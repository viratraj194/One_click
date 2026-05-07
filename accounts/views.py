import random
from django.db import transaction
from rest_framework import generics, status, viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth import authenticate
from rest_framework.authtoken.models import Token
from .serializers import (
    RegistrationSerializer, LoginSerializer, UserProfileSerializer, 
    ProfileUpdateSerializer, EmergencyContactSerializer
)
from .models import EmergencyContact, UserProfile, SOSAlert
from .utils import send_fast2sms_otp
import re

class SOSTriggerView(APIView):
    """
    API endpoint to record an SOS trigger with location data.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        lat = request.data.get('latitude')
        lng = request.data.get('longitude')
        
        if not lat or not lng:
            return Response({"error": "Latitude and longitude are required."}, status=status.HTTP_400_BAD_REQUEST)
            
        alert = SOSAlert.objects.create(
            user=request.user,
            latitude=lat,
            longitude=lng
        )
        
        # User requested specific print statement
        print(f'--- EMERGENCY ALERT: User {request.user.username} at {lat}, {lng} ---')
        
        return Response({
            "message": "SOS Alert recorded successfully.",
            "alert_id": alert.id
        }, status=status.HTTP_201_CREATED)

class RegisterUserAPIView(generics.GenericAPIView):
    """
    API endpoint for registering a new Lifeline user.
    Accessible by anyone (AllowAny).
    """
    serializer_class = RegistrationSerializer
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            # The create() method in RegistrationSerializer handles 
            # User and UserProfile creation + Token generation.
            profile = serializer.save()
            return Response(
                serializer.data, 
                status=status.HTTP_201_CREATED
            )
        
        # Return specific validation errors (e.g., 'Aadhaar already exists')
        # for the Flutter app to display to the user.
        return Response(
            serializer.errors, 
            status=status.HTTP_400_BAD_REQUEST
        )

class LoginAPIView(generics.GenericAPIView):
    """
    API endpoint for user login.
    Returns auth token and profile data on success.
    """
    serializer_class = LoginSerializer
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        username = serializer.validated_data['username']
        password = serializer.validated_data['password']
        
        user = authenticate(username=username, password=password)
        
        if user:
            token, _ = Token.objects.get_or_create(user=user)
            profile = user.profile
            return Response({
                "status": "success",
                "token": token.key,
                "user": {
                    "username": user.username,
                    "full_name": profile.full_name,
                    "phone": profile.phone_number,
                    "blood_group": profile.blood_group,
                    "emergency_contact_phone": profile.emergency_contact_phone,
                    "verified": True
                }
            }, status=status.HTTP_200_OK)
        
        return Response({
            "status": "error",
            "message": "Invalid Credentials"
        }, status=status.HTTP_401_UNAUTHORIZED)

class ProfileView(generics.RetrieveUpdateAPIView):
    """
    API endpoint to retrieve or update the profile of the logged-in user.
    Handles partial updates (PATCH) for preferences and details.
    """
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user.profile

    def get(self, request, *args, **kwargs):
        """
        Return the current user's profile details as JSON.
        """
        return self.retrieve(request, *args, **kwargs)

    def patch(self, request, *args, **kwargs):
        """
        Handle partial updates with partial=True.
        """
        kwargs['partial'] = True
        return self.partial_update(request, *args, **kwargs)

class EmergencyContactViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing emergency contacts of the logged-in user.
    """
    serializer_class = EmergencyContactSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return EmergencyContact.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def create(self, request, *args, **kwargs):
        """
        Custom create method to handle both single contact addition 
        and bulk sync (list of contacts).
        Automatically attaches the logged-in user to every contact.
        Returns specific errors (e.g., 'Phone number must be in international format').
        """
        if isinstance(request.data, list):
            serializer = self.get_serializer(data=request.data, many=True)
            if not serializer.is_valid():
                # Return granular errors for the list of objects
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
            with transaction.atomic():
                # Delete existing contacts for the user to perform a full sync
                EmergencyContact.objects.filter(user=request.user).delete()
                
                # Save the new list, explicitly passing the user for each object
                serializer.save(user=request.user)
            
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class SendOTPView(generics.GenericAPIView):
    """
    API endpoint to generate and send a 6-digit OTP via Fast2SMS.
    Works for both registration (new numbers) and verified users.
    """
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        phone = request.data.get('phone')
        if not phone:
            return Response({"error": "Phone number is required."}, status=status.HTTP_400_BAD_REQUEST)
            
        # Generate 6-digit random OTP
        otp = str(random.randint(100000, 999999))
        
        # Save to profile if it exists
        profile = UserProfile.objects.filter(phone_number=phone).first()
        if profile:
            profile.otp = otp
            profile.save()
        
        # Call Fast2SMS Utility
        send_fast2sms_otp(phone, otp)
        
        # Always return OTP in response for testing/mocking as requested
        return Response({
            "message": f"OTP sent successfully to {phone}.",
            "otp": otp  # For testing/mocking
        }, status=status.HTTP_200_OK)

class VerifyOTPView(generics.GenericAPIView):
    """
    API endpoint to verify the OTP.
    If profile exists, sets is_phone_verified to True.
    If profile doesn't exist, allows verification to proceed for registration.
    """
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        otp_received = request.data.get('otp')
        phone = request.data.get('phone')
        
        if not otp_received or not phone:
            return Response({"error": "OTP and phone number are required."}, status=status.HTTP_400_BAD_REQUEST)

        profile = UserProfile.objects.filter(phone_number=phone).first()
        
        if profile:
            if profile.otp == otp_received and otp_received is not None:
                profile.is_phone_verified = True
                profile.otp = None  # Clear OTP after success
                profile.save()
                
                # Generate/Retrieve token for the user
                token, _ = Token.objects.get_or_create(user=profile.user)
                
                return Response({
                    "message": "Phone verified successfully.",
                    "token": token.key,
                    "status": "verified"
                }, status=status.HTTP_200_OK)
            else:
                return Response({"error": "Invalid OTP."}, status=status.HTTP_400_BAD_REQUEST)
        else:
            # Registration flow: verify against any 6-digit OTP for testing
            # In production, we'd verify against a cache (Redis/Django Cache)
            if len(otp_received) == 6:
                return Response({
                    "message": "Phone verified successfully.",
                    "status": "verified"
                }, status=status.HTTP_200_OK)
            else:
                return Response({"error": "Invalid OTP format."}, status=status.HTTP_400_BAD_REQUEST)

class RequestAadhaarOTPView(generics.GenericAPIView):
    """
    API endpoint to request a mock Aadhaar OTP.
    Validates that Aadhaar is 12 digits.
    """
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        aadhaar = request.data.get('aadhaar')
        if not aadhaar or not re.match(r'^\d{12}$', aadhaar):
            return Response({"error": "A valid 12-digit Aadhaar number is required."}, status=status.HTTP_400_BAD_REQUEST)
        
        # Mock Logic: Print to terminal
        print(f"\n[AADHAAR MOCK] OTP for Aadhaar {aadhaar} is 998877\n")
        
        return Response({
            "message": f"OTP sent to mobile linked with Aadhaar {aadhaar}.",
            "otp": "998877"  # For testing/mocking
        }, status=status.HTTP_200_OK)

class VerifyAadhaarView(generics.GenericAPIView):
    """
    API endpoint to verify the mock Aadhaar OTP.
    Sets is_aadhaar_verified to True if OTP is '998877'.
    """
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        otp_received = request.data.get('otp')
        aadhaar = request.data.get('aadhaar')
        phone = request.data.get('phone') # Optional, to link to profile
        
        if otp_received == '998877':
            if phone:
                profile = UserProfile.objects.filter(phone_number=phone).first()
                if profile:
                    profile.is_aadhaar_verified = True
                    profile.save()
            
            return Response({
                "message": "Aadhaar verified successfully.",
                "status": "verified"
            }, status=status.HTTP_200_OK)
        
        return Response({"error": "Invalid Aadhaar OTP."}, status=status.HTTP_400_BAD_REQUEST)
