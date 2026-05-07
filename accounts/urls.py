from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    RegisterUserAPIView, LoginAPIView, ProfileView, 
    EmergencyContactViewSet,
    SendOTPView, VerifyOTPView, RequestAadhaarOTPView, VerifyAadhaarView,
    SOSTriggerView
)

router = DefaultRouter()
router.register(r'contacts', EmergencyContactViewSet, basename='emergency-contact')

urlpatterns = [
    path('', include(router.urls)),
    path('register/', RegisterUserAPIView.as_view(), name='register'),
    path('login/', LoginAPIView.as_view(), name='login'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('send-otp/', SendOTPView.as_view(), name='send-otp'),
    path('verify-phone/', VerifyOTPView.as_view(), name='verify-phone'),
    path('aadhaar-otp/', RequestAadhaarOTPView.as_view(), name='aadhaar-otp'),
    path('aadhaar-verify/', VerifyAadhaarView.as_view(), name='aadhaar-verify'),
    path('sos-trigger/', SOSTriggerView.as_view(), name='sos-trigger'),
]
