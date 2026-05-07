import os
import django
from pathlib import Path

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lifeline_project.settings')

try:
    from django.conf import settings
    
    print("--- Lifeline Diagnostic Report ---")
    
    # 1. Print current ROOT_URLCONF
    if hasattr(settings, 'ROOT_URLCONF'):
        print(f"1. ROOT_URLCONF is set to: '{settings.ROOT_URLCONF}'")
    else:
        print("1. ERROR: ROOT_URLCONF is NOT defined in settings.py")

    # 2. Check if lifeline_project/urls.py exists
    urls_path = Path('lifeline_project/urls.py')
    if urls_path.exists():
        print(f"2. SUCCESS: '{urls_path}' exists.")
    else:
        print(f"2. ERROR: '{urls_path}' NOT found. Check your directory structure.")

    # 3. Naming consistency check
    project_dir = Path('lifeline_project')
    if project_dir.exists() and project_dir.is_dir():
        print(f"3. SUCCESS: Project directory '{project_dir}' exists.")
        
        # Check if settings.py matches the folder
        settings_path = project_dir / 'settings.py'
        if settings_path.exists():
            print(f"   - Found '{settings_path}' inside.")
        else:
            print(f"   - WARNING: 'settings.py' not found in '{project_dir}'.")
    else:
        print(f"3. ERROR: Project directory 'lifeline_project' NOT found.")
        print("   HINT: You might need to rename your main configuration folder to 'lifeline_project'.")

except Exception as e:
    print(f"CRITICAL ERROR: {e}")
    print("\nTroubleshooting tips:")
    print("- Ensure you are running this from the project root.")
    print("- Ensure 'lifeline_project' folder has an '__init__.py' file.")
