import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/listing_service.dart';
import '../models/house_model.dart';

class AnimatedText extends StatelessWidget {
  final String text;
  final Duration duration;
  final TextStyle style;

  const AnimatedText({
    super.key,
    required this.text,
    required this.duration,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Text(text, style: style),
    );
  }
}

class EditListingPage extends StatefulWidget {
  final HouseModel house;

  const EditListingPage({super.key, required this.house});

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final List<File> _newImages = [];
  List<String> _existingImages = [];
  bool _isUpdating = false;
  late AnimationController _controller;

  // Контроллеры для полей
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();

  final List<String> _cities = [
    // Беларусь
    'Минск, Беларусь',
    'Брест, Беларусь',
    'Витебск, Беларусь',
    'Гомель, Беларусь',
    'Гродно, Беларусь',
    'Могилёв, Беларусь',
    // Россия
    'Москва, Россия',
    'Санкт-Петербург, Россия',
  ];
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.forward();

    // Заполняем контроллеры существующими данными
    _titleController.text = widget.house.title;
    _descController.text = widget.house.description;
    _locationController.text = widget.house.location;
    _priceController.text = widget.house.price.toString();
    _bedroomsController.text = widget.house.bedrooms.toString();
    _bathroomsController.text = widget.house.bathrooms.toString();
    _areaController.text = widget.house.area.toString();
    _existingImages = List.from(widget.house.images);
    _selectedCity = widget.house.location;
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _addImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        print('DEBUG: Выбрано изображение: ${image.path}');
        setState(() {
          _newImages.add(File(image.path));
        });
      }
    } catch (e) {
      print('ERROR: Ошибка при выборе изображения: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выборе изображения: $e')),
      );
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(File file) {
    setState(() {
      _newImages.remove(file);
    });
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      final updatedHouse = widget.house.copyWith(
        title: _titleController.text,
        description: _descController.text,
        location: _selectedCity!,
        price: double.parse(_priceController.text),
        bedrooms: int.parse(_bedroomsController.text),
        bathrooms: int.parse(_bathroomsController.text),
        area: int.parse(_areaController.text),
        images: [..._existingImages],
      );

      await ListingService().updateListing(updatedHouse, _newImages);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Объявление обновлено')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: AnimatedText(
          text: 'Редактировать объявление',
          duration: const Duration(milliseconds: 500),
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade600, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50.withOpacity(0.2),
              Colors.deepPurple.shade50.withOpacity(0.1),
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildImageSection(),
              const SizedBox(height: 30),
              _buildInputSection(),
              const SizedBox(height: 40),
              _buildUpdateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      )),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_library, color: Colors.deepPurple.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Фотографии',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildAddPhotoButton(),
                  ..._existingImages.asMap().entries.map((entry) => _buildExistingImagePreview(entry.value, entry.key)),
                  ..._newImages.map((image) => _buildNewImagePreview(image)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _addImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.blue.shade200,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, 
              color: Colors.blue.shade600,
              size: 32),
            const SizedBox(height: 8),
            Text('Добавить',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingImagePreview(String url, int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => _removeExistingImage(index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, 
                color: Colors.white,
                size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImagePreview(File image) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: FileImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => _removeNewImage(image),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, 
                color: Colors.white,
                size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        )),
        child: Column(
          children: [
            _buildSectionHeader('Основная информация', Icons.info),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _titleController,
              label: 'Название объявления',
              icon: Icons.title,
              validator: (v) => v!.isEmpty ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _descController,
              label: 'Описание',
              icon: Icons.description,
              maxLines: 4,
              validator: (v) => v!.isEmpty ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 20),
            _buildSectionHeader('Характеристики', Icons.analytics),
            const SizedBox(height: 16),
            _buildCityDropdown(),
            const SizedBox(height: 20),
            _buildNumberInputs(),
            const SizedBox(height: 20),
            _buildSliders(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.deepPurple.shade600),
        ),
        const SizedBox(width: 12),
        Text(title,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple.shade800,
          )),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: GoogleFonts.montserrat(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: Colors.grey.shade600),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
            ),
            child: Icon(icon, color: Colors.deepPurple.shade600),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.deepPurple.shade400,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        errorStyle: GoogleFonts.montserrat(
          color: Colors.red.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCity,
      items: _cities.map((city) => DropdownMenuItem(
        value: city,
        child: Text(city, style: GoogleFonts.montserrat()),
      )).toList(),
      onChanged: (v) => setState(() => _selectedCity = v),
      decoration: InputDecoration(
        labelText: 'Город',
        labelStyle: GoogleFonts.montserrat(color: Colors.grey.shade600),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
            ),
            child: Icon(Icons.location_city, color: Colors.deepPurple.shade600),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.deepPurple.shade400,
            width: 2,
          ),
        ),
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      menuMaxHeight: 300,
      validator: (v) => v == null ? 'Выберите город' : null,
    );
  }

  Widget _buildNumberInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildNumberField(
              controller: _priceController,
              label: 'Цена, ₽',
              icon: Icons.attach_money,
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildNumberField(
              controller: _areaController,
              label: 'Площадь, м²',
              icon: Icons.square_foot,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.montserrat(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: Colors.grey.shade600),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
            ),
            child: Icon(icon, color: Colors.deepPurple.shade600),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.deepPurple.shade400,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
    );
  }

  Widget _buildSliders() {
    return Column(
      children: [
        _buildSlider(
          value: double.tryParse(_bedroomsController.text) ?? 1.0,
          label: 'Спальни',
          icon: Icons.bed,
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: (value) => setState(() => _bedroomsController.text = value.round().toString()),
        ),
        const SizedBox(height: 20),
        _buildSlider(
          value: double.tryParse(_bathroomsController.text) ?? 1.0,
          label: 'Ванные',
          icon: Icons.bathtub,
          min: 1,
          max: 3,
          divisions: 2,
          onChanged: (value) => setState(() => _bathroomsController.text = value.round().toString()),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required double value,
    required String label,
    required IconData icon,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.deepPurple.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.deepPurple.shade800,
              ),
            ),
            const Spacer(),
            Text(
              value.round().toString(),
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple.shade600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.round().toString(),
          onChanged: onChanged,
          activeColor: Colors.deepPurple.shade600,
          inactiveColor: Colors.deepPurple.shade100,
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isUpdating ? null : _update,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isUpdating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Обновить',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
} 