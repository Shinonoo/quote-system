import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/remote_data_source.dart';
import '../../core/errors/api_exception.dart';
import '../../utils/error_handler.dart';
import '../../constants/app_colors.dart';
import '../widgets/quote/add_item_form.dart';
import 'home_screen.dart';  // Same folder now

class CreateQuoteScreen extends StatefulWidget {
  const CreateQuoteScreen({Key? key}) : super(key: key);

  @override
  _CreateQuoteScreenState createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends State<CreateQuoteScreen> {
  final ApiClient _apiClient = ApiClient();
  final _scrollController = ScrollController();

  String _companyName = '';
  String _companyLocation = '';
  String _attentionName = '';
  String _attentionPosition = '';
  String _projectName = '';
  String _projectLocation = '';

  final List<Map<String, dynamic>> _cartItems = [];
  List<dynamic> _equipmentList =[];
  bool _isLoadingEquipment = true;
  bool _isSubmitting = false;
  int _loggedInUserId = 1;

  @override
  void initState() {
    super.initState();
    _fetchEquipment();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _loggedInUserId = prefs.getInt('user_id') ?? 1);
  }

  Future<void> _fetchEquipment() async {
    try {
      final response = await _apiClient.dio.get('/quotes/equipment');
      if (mounted) {
        setState(() {
          _equipmentList = response.data['data'] ?? response.data;
          _isLoadingEquipment = false;
        });
      }
    } on DioException catch (e) {
      final error = e.error is ApiException ? e.error as ApiException : ApiException('Failed to load equipment.');
      if (mounted) {
        setState(() => _isLoadingEquipment = false);
        handleError(context, error);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEquipment = false);
        handleError(context, ApiException('Unexpected error loading equipment.'));
      }
    }
  }

  Future<void> _submitBulkQuote() async {
    if (_companyName.isEmpty || _projectName.isEmpty) {
      handleError(context, ApiException('Please enter Company Name & Project Name.'));
      return;
    }
    if (_cartItems.isEmpty) {
      handleError(context, ApiException('Please add at least one item.'));
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      "company_name": _companyName,
      "company_location": _companyLocation,
      "attention_name": _attentionName,
      "attention_position": _attentionPosition,
      "customer_project": _projectName,
      "project_location": _projectLocation,
      "created_by": _loggedInUserId,
      "items": _cartItems,
    };

    try {
      final response = await _apiClient.dio.post('/quotes/create', data: payload);
      if (mounted) {
        _showSuccessDialog(response.data['reference_no']);
      }
    } on DioException catch (e) {
      if (mounted) handleError(context, e.error is ApiException ? e.error as ApiException : ApiException('Failed to create quote.'));
    } catch (e) {
      if (mounted) handleError(context, ApiException('Unexpected error. Please try again.'));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(String referenceNo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 64),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quote Created!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Reference Number',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
                ),
                child: Text(
                  referenceNo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: const Color.fromARGB(255, 13, 5, 5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddItemModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: AddItemForm(
            equipmentList: _equipmentList,
            existingCartItems: _cartItems,
            onAddMany: (items) {
              setState(() => _cartItems.addAll(items));
              Navigator.pop(context);
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, Function(String) onChanged, {String? hint}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.secondaryGreen),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      body: _isLoadingEquipment
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const[
                  CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 3),
                  SizedBox(height: 16),
                  Text('Loading equipment...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : CustomScrollView(
              controller: _scrollController,
              slivers:[
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: AppColors.primaryGreen,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'New Quotation',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors:[AppColors.primaryGreen, AppColors.secondaryGreen],
                        ),
                      ),
                      child: Stack(
                        children:[
                          Positioned(
                            right: -50,
                            top: -50,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            left: -30,
                            bottom: -30,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        _buildClientDetailsCard(),
                        const SizedBox(height: 24),
                        _buildEquipmentSection(),
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

  Widget _buildClientDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children:[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business_center, color: AppColors.primaryGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Client Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField('Company Name *', Icons.business, (v) => _companyName = v),
              const SizedBox(height: 16),
              _buildTextField('Company Location', Icons.location_on, (v) => _companyLocation = v),
              const SizedBox(height: 16),
              Row(
                children:[
                  Expanded(child: _buildTextField('Attention Name', Icons.person, (v) => _attentionName = v)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Position', Icons.work_outline, (v) => _attentionPosition = v)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Project Name *', Icons.folder_special, (v) => _projectName = v),
              const SizedBox(height: 16),
              _buildTextField('Project Location', Icons.map, (v) => _projectLocation = v, hint: 'e.g. UNDERGROUND'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
                ),
                child: Row(
                  children: const[
                    Icon(Icons.verified, color: AppColors.accentGold, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Date & Reference No. will be auto-generated upon submission',
                        style: TextStyle(
                          color: AppColors.accentGold,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildEquipmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  const Text(
                    "Equipment Items",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_cartItems.length} items added",
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddItemModal,
                icon: const Icon(Icons.add, size: 20),
                label: const Text("Add Item"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _cartItems.isEmpty ? _buildEmptyCart() : _buildCartList(),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow:[
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            "No equipment added yet",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Tap 'Add Item' to start building your quote",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        final eqName = _resolveEquipmentName(item);
        return Dismissible(
          key: Key('item_$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => setState(() => _cartItems.removeAt(index)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow:[
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                leading: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "${item['item_code']}",
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                title: Text(
                  eqName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  "${item['length']} × ${item['width']} • Qty: ${item['qty']}",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: () => setState(() => _cartItems.removeAt(index)),
                ),
                children:[
                  _buildItemDetails(item),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemDetails(Map<String, dynamic> item) {
    final customizations = item['customizations'] as Map<String, dynamic>;
    final customEntries = customizations.entries.where((e) => 
      !['custom_desc', 'custom_price', 'custom_req'].contains(e.key)
    ).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (customizations['custom_req'] != null) ...[
            const Text(
              "Additional Requirements",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              customizations['custom_req'],
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
          ],
          if (customEntries.isNotEmpty) ...[
            const Text(
              "Customizations",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customEntries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
                  ),
                  child: Text(
                    _formatCustomizationLabel(entry.key, entry.value),
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCustomizationLabel(String key, dynamic value) {
    final labels = {
      'insect_screen': 'Insect Screen',
      'bird_screen': 'Bird Screen',
      'obvd': 'OBVD/OBB',
      'radial_damper': 'Radial Damper',
      'double_frame': 'Double Frame',
      'powder_coat': 'Powder Coat',
    };
    return labels[key] ?? key;
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
          onPressed: _isSubmitting ? null : _submitBulkQuote,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const[
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Creating Quote...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const[
                    Icon(Icons.check_circle_outline),
                    SizedBox(width: 8),
                    Text(
                      "FINISH & SAVE QUOTE",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _resolveEquipmentName(Map<String, dynamic> item) {
    final id = item['equipment_type_id'];
    if (id == null || id == -1) {
      return item['customizations']['custom_desc'] ?? 'Custom Equipment';
    }
    return _equipmentList
        .firstWhere((e) => e['id'] == id, orElse: () => {'name': 'Unknown'})['name'] as String;
  }
}
