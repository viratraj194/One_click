from django.db import models
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
import re

def validate_aadhaar(value):
    if not re.match(r'^\d{12}$', value):
        raise ValidationError('Aadhaar number must be exactly 12 digits.')

def validate_phone(value):
    # Basic international format check: starts with + followed by 10-15 digits
    if not re.match(r'^\+\d{10,15}$', value):
        raise ValidationError('Phone number must be in international format (e.g., +919876543210).')

from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver

class UserProfile(models.Model):
    # ... (existing fields)
    BLOOD_GROUP_CHOICES = [
        ('A+', 'A+'), ('A-', 'A-'),
        ('B+', 'B+'), ('B-', 'B-'),
        ('AB+', 'AB+'), ('AB-', 'AB-'),
        ('O+', 'O+'), ('O-', 'O-'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    full_name = models.CharField(max_length=255)
    phone_number = models.CharField(max_length=20, unique=True, validators=[validate_phone])
    blood_group = models.CharField(max_length=3, choices=BLOOD_GROUP_CHOICES)
    
    # Cybersecurity: Aadhaar number (stored as CharField for now)
    # Plan for future: Use django-fernet-fields for encryption
    aadhaar_number = models.CharField(max_length=12, validators=[validate_aadhaar])
    
    # Medical Data (Integrated as seen in Profile UI)
    allergies = models.TextField(default='None')
    medications = models.TextField(default='None')
    conditions = models.TextField(default='None')

    # Primary Emergency Contact (Directly on profile for quick access)
    # Syncs with the first entry in the EmergencyContact model
    emergency_contact_name = models.CharField(max_length=255, blank=True, null=True)
    emergency_contact_phone = models.CharField(max_length=20, blank=True, null=True, validators=[validate_phone])
    
    # OTP verification fields
    otp = models.CharField(max_length=6, blank=True, null=True)
    is_phone_verified = models.BooleanField(default=False)
    is_aadhaar_verified = models.BooleanField(default=False)
    
    # New Preference Fields
    SOS_TYPE_CHOICES = [
        ('Police', 'Police'),
        ('Ambulance', 'Ambulance'),
        ('Both', 'Both'),
    ]
    sos_type = models.CharField(max_length=20, choices=SOS_TYPE_CHOICES, default='Both')
    silent_mode = models.BooleanField(default=False)
    share_location = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)

    def clean(self):
        super().clean()
        if self.aadhaar_number:
            validate_aadhaar(self.aadhaar_number)
        if self.phone_number:
            validate_phone(self.phone_number)

    def __str__(self):
        return f"{self.full_name} ({self.user.username})"

class EmergencyContact(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='emergency_contacts', null=True, blank=True)
    contact_name = models.CharField(max_length=255)
    relationship = models.CharField(max_length=100)
    phone_number = models.CharField(max_length=20, validators=[validate_phone])

    def clean(self):
        super().clean()
        if self.phone_number:
            validate_phone(self.phone_number)

    def __str__(self):
        owner = self.user.profile.full_name if self.user and hasattr(self.user, 'profile') else "Unknown"
        return f"{self.contact_name} ({self.relationship}) - Contact for {owner}"

# removed sync_primary_contact signal as requested to isolate primary guardian fields from emergency contacts list.

class SOSAlert(models.Model):
    STATUS_CHOICES = [
        ('Active', 'Active'),
        ('Resolved', 'Resolved'),
        ('False Alarm', 'False Alarm'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sos_alerts')
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    timestamp = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Active')

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"SOS Alert from {self.user.username} at {self.timestamp}"
