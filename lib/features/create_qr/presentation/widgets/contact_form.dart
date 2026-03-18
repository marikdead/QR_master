import 'package:flutter/material.dart';

class ContactQrForm extends StatelessWidget {
  const ContactQrForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.emailController,
    required this.companyController,
    required this.websiteController,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController companyController;
  final TextEditingController websiteController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone *',
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: companyController,
          decoration: const InputDecoration(
            labelText: 'Company',
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: websiteController,
          decoration: const InputDecoration(
            labelText: 'Website',
          ),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

