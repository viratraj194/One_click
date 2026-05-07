import os
import django
import sys

# Try to find the settings module dynamically or use a default
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lifeline_project.settings')

try:
    django.setup()
    from accounts.models import UserProfile

    total_users = UserProfile.objects.count()
    print(f"Total registered users: {total_users}")

    if total_users > 0:
        latest_user = UserProfile.objects.latest('created_at')
        print(f"Most Recent Registration:")
        print(f"Name: {latest_user.full_name}")
        print(f"Phone: {latest_user.phone_number}")
    else:
        print("No users registered yet.")
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
