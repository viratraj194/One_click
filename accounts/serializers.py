from rest_framework import serializers
from django.contrib.auth.models import User
from .models import UserProfile, EmergencyContact
from rest_framework.authtoken.models import Token
from django.db import transaction
import re

class RegistrationSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(write_only=True, style={'input_type': 'password'})
    full_name = serializers.CharField(max_length=255)
    phone = serializers.CharField(max_length=20)
    blood_group = serializers.ChoiceField(choices=UserProfile.BLOOD_GROUP_CHOICES)
    aadhaar = serializers.CharField(max_length=12)
    emergency_contact_name = serializers.CharField(max_length=255, required=False, allow_blank=True)
    emergency_contact_phone = serializers.CharField(max_length=20, required=False, allow_blank=True)

    def validate_phone(self, value):
        if UserProfile.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError("This phone number is already registered.")
        if not re.match(r'^\+\d{10,15}$', value):
            raise serializers.ValidationError("Phone number must be in international format (e.g., +919876543210).")
        return value

    def validate_aadhaar(self, value):
        if UserProfile.objects.filter(aadhaar_number=value).exists():
            raise serializers.ValidationError("This Aadhaar number is already registered.")
        if not re.match(r'^\d{12}$', value):
            raise serializers.ValidationError("Aadhaar number must be exactly 12 digits.")
        return value

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("This username is already taken.")
        return value

    def validate_emergency_contact_phone(self, value):
        if value and not re.match(r'^\+\d{10,15}$', value):
            raise serializers.ValidationError("Emergency phone number must be in international format (e.g., +919876543210).")
        return value

    @transaction.atomic
    def create(self, validated_data):
        # 1. Create the Django User with hashed password
        user = User.objects.create_user(
            username=validated_data['username'],
            password=validated_data['password']
        )

        # 2. Create the associated Lifeline UserProfile
        profile = UserProfile.objects.create(
            user=user,
            full_name=validated_data['full_name'],
            phone_number=validated_data['phone'],
            blood_group=validated_data['blood_group'],
            aadhaar_number=validated_data['aadhaar'],
            emergency_contact_name=validated_data.get('emergency_contact_name'),
            emergency_contact_phone=validated_data.get('emergency_contact_phone')
        )
        
        return profile

    def to_representation(self, instance):
        """
        Custom response format to include success message and Auth Token.
        """
        token, _ = Token.objects.get_or_create(user=instance.user)
        
        return {
            "status": "success",
            "message": "Lifeline account created successfully.",
            "token": token.key,
            "user": {
                "username": instance.user.username,
                "full_name": instance.full_name,
                "phone": instance.phone_number,
                "blood_group": instance.blood_group,
                "emergency_contact_name": instance.emergency_contact_name,
                "emergency_contact_phone": instance.emergency_contact_phone,
                "verified": True
            }
        }

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

class EmergencyContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyContact
        fields = ['id', 'contact_name', 'relationship', 'phone_number']
        read_only_fields = ['id']

    def validate_phone_number(self, value):
        if not re.match(r'^\+\d{10,15}$', value):
            raise serializers.ValidationError("Phone number must be in international format (e.g., +919876543210).")
        return value

class UserProfileSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source='full_name', required=False)
    phone = serializers.CharField(source='phone_number', required=False)
    emergency_contacts = serializers.SerializerMethodField()
    
    class Meta:
        model = UserProfile
        fields = [
            'name', 'phone', 'full_name', 'phone_number', 'blood_group', 
            'aadhaar_number', 'allergies', 'medications', 
            'conditions', 'emergency_contacts', 'is_phone_verified',
            'is_aadhaar_verified', 'emergency_contact_name', 
            'emergency_contact_phone', 'sos_type', 'silent_mode', 
            'share_location'
        ]
        read_only_fields = [
            'aadhaar_number', 'is_phone_verified', 
            'is_aadhaar_verified', 'emergency_contacts'
        ]

    def get_emergency_contacts(self, obj):
        contacts = obj.user.emergency_contacts.all()
        return EmergencyContactSerializer(contacts, many=True).data

class ProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = [
            'full_name', 'phone_number', 'allergies', 'medications', 
            'conditions', 'blood_group', 'emergency_contact_name', 
            'emergency_contact_phone', 'sos_type', 'silent_mode', 
            'share_location'
        ]
        extra_kwargs = {
            'phone_number': {'required': False},
            'full_name': {'required': False},
            'blood_group': {'required': False},
        }
