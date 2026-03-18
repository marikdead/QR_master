import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_code_scanner/app/theme/app_typography.dart';

import '../../../app/theme/app_components.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/analytics/appsflyer_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injector.dart';
import '../../../shared/models/qr_type.dart';
import '../../../shared/widgets/header.dart';
import '../../../shared/widgets/pro_feature_badge.dart';
import '../../my_qr_codes/domain/saved_qr_model.dart';
import '../../subscription/data/apphud_repository.dart';
import '../domain/generated_qr_model.dart';
import '../domain/qr_content_type.dart';
import 'widgets/color_picker_row.dart';
import 'widgets/contact_form.dart';
import 'widgets/content_type_selector.dart';
import 'widgets/text_form.dart';
import 'widgets/url_form.dart';
import 'widgets/wifi_form.dart';

class CreateQrScreen extends StatefulWidget {
  const CreateQrScreen({super.key, this.initial});

  final SavedQrCode? initial;

  @override
  State<CreateQrScreen> createState() => _CreateQrScreenState();
}

class _CreateQrScreenState extends State<CreateQrScreen> {
  QrContentType _type = QrContentType.url;
  Color _color = const Color(0xFF1A1A1A);

  final _formKey = GlobalKey<FormState>();

  final _url = TextEditingController();
  final _text = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _website = TextEditingController();
  final _ssid = TextEditingController();
  final _wifiPass = TextEditingController();
  String _wifiSecurity = 'WPA/WPA2';

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;

    _color = Color(initial.colorValue);
    switch (initial.type) {
      case QrType.url:
        _type = QrContentType.url;
        _url.text = initial.content;
        break;
      case QrType.text:
        _type = QrContentType.text;
        _text.text = initial.content;
        break;
      case QrType.contact:
      case QrType.wifi:
      case QrType.unknown:
        _type = QrContentType.text;
        _text.text = initial.content;
        break;
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _text.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _company.dispose();
    _website.dispose();
    _ssid.dispose();
    _wifiPass.dispose();
    super.dispose();
  }

  String _buildPayload() {
    switch (_type) {
      case QrContentType.url:
        return _url.text.trim();
      case QrContentType.text:
        return _text.text.trim();
      case QrContentType.contact:
        return _buildVCard();
      case QrContentType.wifi:
        return _buildWifiString();
    }
  }

  String _buildVCard() {
    final f = _firstName.text.trim();
    final l = _lastName.text.trim();
    final p = _phone.text.trim();
    final e = _email.text.trim();
    final c = _company.text.trim();
    final w = _website.text.trim();

    return '''BEGIN:VCARD
VERSION:3.0
N:$l;$f;;;
FN:$f $l
TEL:$p
EMAIL:$e
ORG:$c
URL:$w
END:VCARD''';
  }

  String _buildWifiString() {
    final ssid = _ssid.text.trim();
    final pass = _wifiPass.text;
    final type = switch (_wifiSecurity) {
      'WEP' => 'WEP',
      'None' => '',
      _ => 'WPA',
    };

    if (type.isEmpty) {
      return 'WIFI:T:;S:$ssid;P:;';
    }

    return 'WIFI:T:$type;S:$ssid;P:$pass;;';
  }

  String? _validatePayload(String payload) {
    switch (_type) {
      case QrContentType.url:
        if (payload.isEmpty) return 'Введите URL';
        if (!payload.startsWith('http://') && !payload.startsWith('https://')) {
          return 'URL должен начинаться с http:// или https://';
        }
        return null;
      case QrContentType.text:
        if (payload.isEmpty) return 'Введите текст';
        return null;
      case QrContentType.contact:
        if (_firstName.text.trim().isEmpty) {
          return 'First Name обязателен';
        }
        if (_phone.text.trim().isEmpty) {
          return 'Phone обязателен';
        }
        if (_email.text.trim().isNotEmpty &&
            !_email.text.contains('@')) {
          return 'Некорректный email';
        }
        return null;
      case QrContentType.wifi:
        if (_ssid.text.trim().isEmpty) return 'Введите SSID';
        if (_wifiSecurity != 'None' && _wifiPass.text.isEmpty) {
          return 'Введите пароль Wi‑Fi';
        }
        return null;
    }
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = _buildPayload();
    final err = _validatePayload(payload);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    await injector<AppsFlyerService>().logEvent(AppsFlyerService.eventCreateQr);
    if (!mounted) return;

    final model = GeneratedQrModel(
      content: payload,
      type: switch (_type) {
        QrContentType.url => QrType.url,
        QrContentType.text => QrType.text,
        QrContentType.contact => QrType.contact,
        QrContentType.wifi => QrType.wifi,
      },
      color: _color,
      createdAt: DateTime.now(),
    );

    await context.push(AppConstants.routeGeneratedQr, extra: model);
  }

  Future<void> _addLogoTapped() async {
    final hasPremium = await injector<ApphudRepository>().hasPremiumAccess();
    if (!mounted) return;
    if (!hasPremium) {
      context.push(AppConstants.routePaywall);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logo support (Pro) coming next')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ScreenHeader(
                title: isEdit ? 'Edit QR Code' : 'Create QR Code',
                onClose: () => context.go('/home'),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Text('Content Type', style: AppTextStyles.title2),
                    const SizedBox(height: 10),
                    ContentTypeSelector(
                      value: _type,
                      onChanged: (t) => setState(() => _type = t),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      switch (_type) {
                        QrContentType.url => 'Website URL',
                        QrContentType.text => 'Text',
                        QrContentType.contact => 'Contact Info',
                        QrContentType.wifi => 'Wi-Fi Network',
                      },
                      style: Theme
                          .of(context)
                          .textTheme
                          .headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    _FormBlock(
                      type: _type,
                      url: _url,
                      text: _text,
                      firstName: _firstName,
                      lastName: _lastName,
                      phone: _phone,
                      email: _email,
                      company: _company,
                      website: _website,
                      ssid: _ssid,
                      wifiPass: _wifiPass,
                      wifiSecurity: _wifiSecurity,
                      onWifiSecurityChanged: (v) =>
                          setState(() => _wifiSecurity = v),
                    ),
                    const SizedBox(height: 18),
                    Text('Design Options', style: Theme
                        .of(context)
                        .textTheme
                        .headlineMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(width: 60, child: Text('Color')),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ColorPickerRow(
                            value: _color,
                            onChanged: (c) => setState(() => _color = c),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _addLogoTapped,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme
                              .radiusLarge),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.image_outlined),
                            SizedBox(width: 10),
                            Expanded(child: Text('+ Add Logo')),
                            ProFeatureBadge(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryGradientButton(
                        onPressed: _generate,
                        label: 'Generate QR Code',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _FormBlock extends StatelessWidget {
  const _FormBlock({
    required this.type,
    required this.url,
    required this.text,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.company,
    required this.website,
    required this.ssid,
    required this.wifiPass,
    required this.wifiSecurity,
    required this.onWifiSecurityChanged,
  });

  final QrContentType type;
  final TextEditingController url;
  final TextEditingController text;
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController company;
  final TextEditingController website;
  final TextEditingController ssid;
  final TextEditingController wifiPass;
  final String wifiSecurity;
  final ValueChanged<String> onWifiSecurityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.border),
      ),
      child: switch (type) {
        QrContentType.url => UrlQrForm(controller: url),
        QrContentType.text => TextQrForm(controller: text),
        QrContentType.contact => ContactQrForm(
            firstNameController: firstName,
            lastNameController: lastName,
            phoneController: phone,
            emailController: email,
            companyController: company,
            websiteController: website,
          ),
        QrContentType.wifi => WifiQrForm(
            ssidController: ssid,
            passwordController: wifiPass,
            securityValue: wifiSecurity,
            onSecurityChanged: onWifiSecurityChanged,
          ),
      },
    );
  }
}

