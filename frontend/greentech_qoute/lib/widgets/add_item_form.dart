import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/dim_row.dart';
import '../models/custom_customization.dart';

class AddItemForm extends StatefulWidget {
  final List<dynamic> equipmentList;
  final List<Map<String, dynamic>> existingCartItems;
  final Function(List<Map<String, dynamic>>) onAddMany;

  const AddItemForm({
    Key? key,
    required this.equipmentList,
    required this.existingCartItems,
    required this.onAddMany,
  }) : super(key: key);

  @override
  State<AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  bool _isCustomEntry = false;
  final TextEditingController _customDescCtrl = TextEditingController();
  final TextEditingController _customCodeCtrl = TextEditingController();
  final TextEditingController _customPriceCtrl = TextEditingController(text: "1500");

  int? _selectedId;
  final List<DimRow> _rows = [DimRow()];

  bool _masterInsect = false;
  bool _masterBird = false;
  bool _masterObvd = false;
  bool _masterRadial = false;
  bool _masterDouble = false;
  bool _masterPowder = false;

  bool _isAllowed(String modifier) {
    if (_isCustomEntry) return true;
    if (_selectedId == null) return false;
    final eq = widget.equipmentList.firstWhere(
      (e) => e['id'] == _selectedId,
      orElse: () => {'allowed_customizations': []},
    );
    final List<dynamic> allowedList = eq['allowed_customizations'] ??[];
    return allowedList.contains(modifier);
  }

  void _addRow() => setState(() => _rows.add(DimRow()));

  void _removeRow(int i) {
    if (_rows.length > 1) {
      setState(() {
        _rows[i].dispose();
        _rows.removeAt(i);
      });
    }
  }

  void _addCustomCustomization(int rowIndex) {
    setState(() {
      _rows[rowIndex].customCustomizations.add(CustomCustomization());
    });
  }

  void _removeCustomCustomization(int rowIndex, int ccIndex) {
    setState(() {
      _rows[rowIndex].customCustomizations.removeAt(ccIndex);
    });
  }

  void _applyToAll() {
    setState(() {
      for (var row in _rows) {
        if (_isAllowed('insect')) row.insect = _masterInsect;
        if (_isAllowed('bird')) row.bird = _masterBird;
        if (_isAllowed('obvd')) row.obvd = _masterObvd;
        if (_isAllowed('radial')) row.radial = _masterRadial;
        if (_isAllowed('doubleFrame')) row.doubleFrame = _masterDouble;
        if (_isAllowed('powder')) row.powderCoat = _masterPowder;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Applied to all ${_rows.length} rows"),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_isCustomEntry && _selectedId == null) return;

    String baseCode = 'ITEM';
    int existingCount = 0;

    if (!_isCustomEntry) {
      final selectedEquipment = widget.equipmentList.firstWhere((e) => e['id'] == _selectedId);
      baseCode = selectedEquipment['code'] ?? 'ITEM';
      existingCount = widget.existingCartItems.where((it) => it['equipment_type_id'] == _selectedId).length;
    } else {
      baseCode = _customCodeCtrl.text.trim();
    }

    final itemsToAdd = <Map<String, dynamic>>[];

    for (int i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final length = double.tryParse(row.lengthCtrl.text.trim()) ?? 0;
      final width = double.tryParse(row.widthCtrl.text.trim()) ?? 0;
      final qty = int.tryParse(row.qtyCtrl.text.trim()) ?? 1;
      final itemCode = _isCustomEntry ? baseCode : '$baseCode-${existingCount + i + 1}';

      final custom = <String, dynamic>{};

      if (_isCustomEntry) {
        custom['custom_desc'] = _customDescCtrl.text.trim();
        custom['custom_price'] = double.tryParse(_customPriceCtrl.text.trim()) ?? 0;
      }

      if (row.customReqCtrl.text.isNotEmpty) custom['custom_req'] = row.customReqCtrl.text.trim();
      if (row.insect && _isAllowed('insect')) custom['insect_screen'] = 1.2;
      if (row.bird && _isAllowed('bird')) custom['bird_screen'] = 1.5;
      if (row.obvd && _isAllowed('obvd')) custom['obvd'] = 1.3;
      if (row.radial && _isAllowed('radial')) custom['radial_damper'] = 1.4;
      if (row.doubleFrame && _isAllowed('doubleFrame')) custom['double_frame'] = 1.15;

      if (row.powderCoat && _isAllowed('powder')) {
        custom['powder_coat'] = {
          'price': 500,
          'finish': row.paintFinish,
          'color': row.paintColor,
        };
      }

      if (row.customCustomizations.isNotEmpty) {
        custom['custom_modifiers'] = row.customCustomizations.map((cc) => cc.toJson()).toList();
      }

      itemsToAdd.add({
        "equipment_type_id": _isCustomEntry ? -1 : _selectedId,
        "item_code": itemCode,
        "length": length,
        "width": width,
        "qty": qty,
        "customizations": custom,
        "discount_type": "none",
        "discount_value": 0,
      });
    }

    widget.onAddMany(itemsToAdd);
  }

  @override
  void dispose() {
    for (final r in _rows) r.dispose();
    _customDescCtrl.dispose();
    _customCodeCtrl.dispose();
    _customPriceCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children:[
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Text(
                        "Add Equipment",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: _isCustomEntry ? AppColors.accentGold.withOpacity(0.1) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children:[
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                "Custom",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isCustomEntry ? AppColors.accentGold : Colors.grey,
                                ),
                              ),
                            ),
                            Switch(
                              value: _isCustomEntry,
                              activeColor: AppColors.accentGold,
                              onChanged: (v) => setState(() {
                                _isCustomEntry = v;
                                _selectedId = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!_isCustomEntry) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Select Equipment Type',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        items: widget.equipmentList.map<DropdownMenuItem<int>>((e) => 
                          DropdownMenuItem(
                            value: e['id'], 
                            child: Text(e['name'], style: const TextStyle(fontSize: 16)),
                          )
                        ).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedId = val;
                            _masterInsect = false; _masterBird = false; _masterObvd = false;
                            _masterRadial = false; _masterDouble = false; _masterPowder = false;
                            for (var r in _rows) {
                              r.insect = false; r.bird = false; r.obvd = false;
                              r.radial = false; r.doubleFrame = false; r.powderCoat = false;
                            }
                          });
                        },
                        validator: (val) => val == null ? 'Please select equipment type' : null,
                      ),
                    ),
                  ] else ...[
                    _buildCustomEntryFields(),
                  ],
                  const SizedBox(height: 24),
                  if (_selectedId != null || _isCustomEntry)
                    _buildGlobalCustomizations(),
                  const SizedBox(height: 24),
                  Text(
                    "Dimensions & Quantities",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _rows.length,
                    itemBuilder: (context, i) => _buildDimensionCard(i),
                  ),
                  const SizedBox(height: 16),
                  _buildAddRowButton(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomEntryFields() {
    return Column(
      children:[
        TextFormField(
          controller: _customDescCtrl,
          decoration: InputDecoration(
            labelText: 'Custom Description *',
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.description, color: Colors.blue),
          ),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children:[
            Expanded(
              child: TextFormField(
                controller: _customCodeCtrl,
                decoration: InputDecoration(
                  labelText: 'Model Code *',
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.code, color: Colors.blue),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _customPriceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Base Price *',
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.attach_money, color: Colors.blue),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlobalCustomizations() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:[AppColors.primaryGreen.withOpacity(0.05), AppColors.secondaryGreen.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children:[
              Icon(Icons.tune, size: 20, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Text(
                "Quick Apply Customizations",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Select options to apply to all items below",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:[
              if (_isAllowed('insect')) _buildToggleChip("Insect Screen", _masterInsect, (v) => setState(() => _masterInsect = v)),
              if (_isAllowed('bird')) _buildToggleChip("Bird Screen", _masterBird, (v) => setState(() => _masterBird = v)),
              if (_isAllowed('obvd')) _buildToggleChip("OBVD/OBB", _masterObvd, (v) => setState(() => _masterObvd = v)),
              if (_isAllowed('radial')) _buildToggleChip("Radial Damper", _masterRadial, (v) => setState(() => _masterRadial = v)),
              if (_isAllowed('doubleFrame')) _buildToggleChip("Double Frame", _masterDouble, (v) => setState(() => _masterDouble = v)),
              if (_isAllowed('powder')) _buildToggleChip("Powder Coat", _masterPowder, (v) => setState(() => _masterPowder = v)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applyToAll,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text("APPLY TO ALL ITEMS"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionCard(int index) {
    final row = _rows[index];
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children:[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children:[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Item #${index + 1}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (_rows.length > 1)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                      onPressed: () => _removeRow(index),
                      tooltip: 'Remove item',
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children:[
                  Expanded(child: _buildDimensionInput(row.lengthCtrl, "Length", Icons.straighten)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDimensionInput(row.widthCtrl, "Width", Icons.straighten)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDimensionInput(row.qtyCtrl, "Qty", Icons.numbers)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: row.customReqCtrl,
                decoration: InputDecoration(
                  labelText: "Special Requirements",
                  hintText: "e.g., Radial damper, aluminum only...",
                  prefixIcon: const Icon(Icons.notes, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
              ),
            ),
            if (_selectedId != null || _isCustomEntry) ...[
              const Divider(height: 24),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text(
                    "Customizations & Modifiers",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    "Tap to configure options",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  children:[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Text(
                            "Standard Options",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:[
                              if (_isAllowed('insect')) _buildToggleChip("Insect", row.insect, (v) => setState(() => row.insect = v)),
                              if (_isAllowed('bird')) _buildToggleChip("Bird", row.bird, (v) => setState(() => row.bird = v)),
                              if (_isAllowed('obvd')) _buildToggleChip("OBVD", row.obvd, (v) => setState(() => row.obvd = v)),
                              if (_isAllowed('radial')) _buildToggleChip("Radial", row.radial, (v) => setState(() => row.radial = v)),
                              if (_isAllowed('doubleFrame')) _buildToggleChip("Dbl Frame", row.doubleFrame, (v) => setState(() => row.doubleFrame = v)),
                              if (_isAllowed('powder')) _buildToggleChip("Powder", row.powderCoat, (v) => setState(() => row.powderCoat = v)),
                            ],
                          ),
                          if (row.powderCoat && _isAllowed('powder')) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdown(["Matte", "Glossy"],
                                      row.paintFinish,
                                      (v) => setState(() => row.paintFinish = v!),
                                      "Finish",
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDropdown(["White", "Black", "Brown", "Custom"],
                                      row.paintColor,
                                      (v) => setState(() => row.paintColor = v!),
                                      "Color",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children:[
                              Text(
                                "Custom Add-ons",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _addCustomCustomization(index),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text("Add Custom"),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.accentGold,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...row.customCustomizations.asMap().entries.map((entry) {
                            final ccIndex = entry.key;
                            final cc = entry.value;
                            return _buildCustomCustomizationRow(index, ccIndex, cc);
                          }).toList(),
                          if (row.customCustomizations.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                              ),
                              child: Row(
                                children:[
                                  const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "No custom add-ons. Tap 'Add Custom' to create special pricing modifiers.",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCustomizationRow(int rowIndex, int ccIndex, CustomCustomization cc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.2)),
      ),
      child: Column(
        children:[
          Row(
            children:[
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: cc.nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Addon Name',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: cc.type,
                    isDense: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    items: const[
                      DropdownMenuItem(value: 'fixed', child: Text('Fixed \$')),
                      DropdownMenuItem(value: 'multiplier', child: Text('× Mult')),
                    ],
                    onChanged: (v) => setState(() => cc.type = v!),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
                onPressed: () => _removeCustomCustomization(rowIndex, ccIndex),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (cc.type == 'fixed')
            TextFormField(
              controller: cc.priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Additional Price',
                prefixText: '\$ ',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            )
          else
            TextFormField(
              controller: cc.multiplierCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Multiplier (e.g., 1.25 for +25%)',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDimensionInput(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (v) => v!.isEmpty ? 'Req' : null,
    );
  }

  Widget _buildToggleChip(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: value ? FontWeight.bold : FontWeight.normal,
          color: value ? AppColors.primaryGreen : Colors.grey.shade700,
        ),
      ),
      selected: value,
      onSelected: onChanged,
      selectedColor: AppColors.primaryGreen.withOpacity(0.15),
      checkmarkColor: AppColors.primaryGreen,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: value ? AppColors.primaryGreen.withOpacity(0.5) : Colors.grey.shade300,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildDropdown(List<String> items, String value, Function(String?) onChanged, String label) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((e) => 
        DropdownMenuItem(
          value: e.toLowerCase(), 
          child: Text(e, style: const TextStyle(fontSize: 13)),
        )
      ).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildAddRowButton() {
    return OutlinedButton.icon(
      onPressed: _addRow,
      icon: const Icon(Icons.add_circle_outline),
      label: const Text("ADD ANOTHER ITEM"),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow:[
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            "ADD ${_rows.length} ITEMS TO QUOTE",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}