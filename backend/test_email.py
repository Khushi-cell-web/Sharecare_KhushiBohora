from django.core.mail import send_mail
result = send_mail('Test', 'Test message', 'khushibohora692@gmail.com', ['khushibohora692@gmail.com'], fail_silently=False)
print(result)
exit()
