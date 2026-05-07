from django.contrib import admin
from .models import UserProfile, EmergencyContact, SOSAlert

@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('full_name', 'phone_number', 'blood_group', 'is_phone_verified', 'created_at')
    search_fields = ('full_name', 'phone_number', 'aadhaar_number')
    list_filter = ('blood_group', 'is_phone_verified')

@admin.register(EmergencyContact)
class EmergencyContactAdmin(admin.ModelAdmin):
    list_display = ('contact_name', 'relationship', 'phone_number', 'user')
    search_fields = ('contact_name', 'phone_number')
    list_filter = ('relationship',)

@admin.register(SOSAlert)
class SOSAlertAdmin(admin.ModelAdmin):
    list_display = ('user', 'latitude', 'longitude', 'timestamp', 'status')
    list_filter = ('status', 'timestamp')
    search_fields = ('user__username', 'user__profile__full_name')
    readonly_fields = ('timestamp',)
