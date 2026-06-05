import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../theme/app_theme.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? client;
  const ClientFormScreen({super.key, this.client});
  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _phone, _whatsapp, _address, _neighborhood, _city, _notes;
  final _phoneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {'#': RegExp(r'[0-9]')});
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _name = TextEditingController(text: c?.name ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _whatsapp = TextEditingController(text: c?.whatsapp ?? '');
    _address = TextEditingController(text: c?.address ?? '');
    _neighborhood = TextEditingController(text: c?.neighborhood ?? '');
    _city = TextEditingController(text: c?.city ?? '');
    _notes = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _whatsapp, _address, _neighborhood, _city, _notes]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final prov = context.read<ClientProvider>();
    final client = Client(
      id: widget.client?.id,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      whatsapp: _whatsapp.text.isEmpty ? null : _whatsapp.text.trim(),
      address: _address.text.isEmpty ? null : _address.text.trim(),
      neighborhood: _neighborhood.text.isEmpty ? null : _neighborhood.text.trim(),
      city: _city.text.isEmpty ? null : _city.text.trim(),
      notes: _notes.text.isEmpty ? null : _notes.text.trim(),
    );
    if (widget.client == null) {
      await prov.addClient(client);
    } else {
      await prov.updateClient(client);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.client == null ? 'Nova Cliente' : 'Editar Cliente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildField('Nome Completo *', _name, Icons.person_rounded, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
            const SizedBox(height: 12),
            _buildField('Telefone *', _phone, Icons.phone_rounded, formatter: _phoneMask, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
            const SizedBox(height: 12),
            _buildField('WhatsApp', _whatsapp, Icons.chat_rounded, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildField('Endereço', _address, Icons.home_rounded),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildField('Bairro', _neighborhood, Icons.location_on_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildField('Cidade', _city, Icons.location_city_rounded)),
            ]),
            const SizedBox(height: 12),
            _buildField('Observações', _notes, Icons.notes_rounded, maxLines: 3),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(widget.client == null ? 'Cadastrar Cliente' : 'Salvar Alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {
    MaskTextInputFormatter? formatter,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      inputFormatters: formatter != null ? [formatter] : null,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
