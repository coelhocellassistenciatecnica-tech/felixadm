import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});
  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _brand, _code, _costPrice, _salePrice, _stock, _minStock;
  String _category = kProductCategories.first;
  String _brandValue = kProductBrands.first;
  String? _imagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _brand = TextEditingController(text: p?.brand ?? kProductBrands.first);
    _code = TextEditingController(text: p?.code ?? '');
    _costPrice = TextEditingController(text: p != null ? p.costPrice.toStringAsFixed(2) : '');
    _salePrice = TextEditingController(text: p != null ? p.salePrice.toStringAsFixed(2) : '');
    _stock = TextEditingController(text: p != null ? '${p.stockQuantity}' : '0');
    _minStock = TextEditingController(text: p != null ? '${p.minStockAlert}' : '5');
    if (p != null) {
      _category = p.category;
      _brandValue = p.brand;
      _imagePath = p.imagePath;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _brand, _code, _costPrice, _salePrice, _stock, _minStock]) c.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final prov = context.read<ProductProvider>();
    final product = Product(
      id: widget.product?.id,
      name: _name.text.trim(),
      brand: _brandValue,
      category: _category,
      code: _code.text.isEmpty ? null : _code.text.trim(),
      costPrice: double.tryParse(_costPrice.text.replaceAll(',', '.')) ?? 0,
      salePrice: double.tryParse(_salePrice.text.replaceAll(',', '.')) ?? 0,
      stockQuantity: int.tryParse(_stock.text) ?? 0,
      minStockAlert: int.tryParse(_minStock.text) ?? 5,
      imagePath: _imagePath,
    );
    if (widget.product == null) {
      await prov.addProduct(product);
    } else {
      await prov.updateProduct(product);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? 'Novo Produto' : 'Editar Produto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 2),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(_imagePath!), fit: BoxFit.cover))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 32),
                          SizedBox(height: 4),
                          Text('Foto', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ]),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome do Produto *', prefixIcon: Icon(Icons.spa_rounded)),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _brandValue,
              decoration: const InputDecoration(labelText: 'Marca *', prefixIcon: Icon(Icons.business_rounded)),
              items: kProductBrands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) => setState(() => _brandValue = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Categoria *', prefixIcon: Icon(Icons.category_rounded)),
              items: kProductCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Código', prefixIcon: Icon(Icons.qr_code_rounded)),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(
                controller: _costPrice,
                decoration: const InputDecoration(labelText: 'Custo (R\$) *', prefixIcon: Icon(Icons.attach_money_rounded)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              )),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(
                controller: _salePrice,
                decoration: const InputDecoration(labelText: 'Venda (R\$) *', prefixIcon: Icon(Icons.sell_rounded)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              )),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(
                controller: _stock,
                decoration: const InputDecoration(labelText: 'Quantidade em Estoque *', prefixIcon: Icon(Icons.inventory_rounded)),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              )),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(
                controller: _minStock,
                decoration: const InputDecoration(labelText: 'Alerta Mínimo', prefixIcon: Icon(Icons.warning_rounded)),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(widget.product == null ? 'Cadastrar Produto' : 'Salvar Alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
