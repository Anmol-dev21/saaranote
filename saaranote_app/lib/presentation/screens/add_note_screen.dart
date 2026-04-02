import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../viewmodels/create_note_viewmodel.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_colors.dart';

/// Screen for adding a new note from text, image, or PDF
class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  bool _generateSummary = true;
  bool _generateFlashcards = true;
  File? _selectedImage;
  File? _selectedPdf;
  int _selectedTab = 0; // 0 = text, 1 = image, 2 = PDF

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Consumer<CreateNoteViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing...'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: AppSpacing.pagePadding.add(AppSpacing.verticalMd),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTabSelector(),
                    AppSpacing.vGapMd,
                    
                    if (_selectedTab == 0) ...[
                      _buildTextInput(),
                    ] else if (_selectedTab == 1) ...[
                      _buildImageInput(),
                    ] else ...[
                      _buildPdfInput(),
                    ],
                    
                    AppSpacing.vGapMd,
                    _buildOptions(),
                    
                    if (viewModel.hasError) ...[
                      AppSpacing.vGapMd,
                      _buildErrorMessage(viewModel.errorMessage!),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      padding: AppSpacing.paddingXs,
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              icon: Icons.text_fields,
              label: 'Text',
              isSelected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
          ),
          Expanded(
            child: _buildTab(
              icon: Icons.image,
              label: 'Image',
              isSelected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ),
          Expanded(
            child: _buildTab(
              icon: Icons.picture_as_pdf,
              label: 'PDF',
              isSelected: _selectedTab == 2,
              onTap: () => setState(() => _selectedTab = 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            AppSpacing.hGapXs,
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Details'),
        AppSpacing.vGapSm,
        TextFormField(
          controller: _titleController,
          decoration: _inputDecoration(
            labelText: 'Title (optional)',
            hintText: 'Enter note title',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        AppSpacing.vGapMd,
        TextFormField(
          controller: _contentController,
          decoration: _inputDecoration(
            labelText: 'Content',
            hintText: 'Enter your note content',
            alignLabelWithHint: true,
          ),
          maxLines: 10,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter note content';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildImageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Details'),
        AppSpacing.vGapSm,
        TextFormField(
          controller: _titleController,
          decoration: _inputDecoration(
            labelText: 'Title (optional)',
            hintText: 'Enter note title',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        AppSpacing.vGapMd,
        _buildSectionTitle('Source image'),
        AppSpacing.vGapSm,
        
        if (_selectedImage != null) ...[
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGapMd,
        ],
        
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_library),
          label: Text(_selectedImage == null ? 'Select Image' : 'Change Image'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        
        if (_selectedImage == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Select an image to extract text using OCR',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildPdfInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Details'),
        AppSpacing.vGapSm,
        TextFormField(
          controller: _titleController,
          decoration: _inputDecoration(
            labelText: 'Title (optional)',
            hintText: 'Will be auto-generated if empty',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        AppSpacing.vGapMd,
        _buildSectionTitle('Source PDF'),
        AppSpacing.vGapSm,
        if (_selectedPdf != null) ...[
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  color: Theme.of(context).colorScheme.primary,
                  size: 36,
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PDF Selected',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        _selectedPdf!.path.split('/').last,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.errorLight),
                  onPressed: () => setState(() => _selectedPdf = null),
                ),
              ],
            ),
          ),
        ] else ...[
          ElevatedButton.icon(
            onPressed: _pickPdf,
            icon: const Icon(Icons.upload_file),
            label: const Text('Select PDF File'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            'Select a PDF file to extract text and create a note',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildOptions() {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Options'),
          SwitchListTile(
            title: const Text('Generate Summary'),
            subtitle: const Text('Automatically create summary'),
            value: _generateSummary,
            onChanged: (value) => setState(() => _generateSummary = value),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Generate Flashcards'),
            subtitle: const Text('Extract key points as flashcards'),
            value: _generateFlashcards,
            onChanged: (value) => setState(() => _generateFlashcards = value),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.errorLight.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorLight.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.errorLight),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.errorLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedPdf = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick PDF: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    final viewModel = context.read<CreateNoteViewModel>();

    if (_selectedTab == 0) {
      // Save from text
      if (!_formKey.currentState!.validate()) return;

      final success = await viewModel.createNoteFromText(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        generateSummary: _generateSummary,
        generateFlashcards: _generateFlashcards,
      );

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note created successfully')),
        );
      }
    } else if (_selectedTab == 1) {
      // Save from image
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image')),
        );
        return;
      }

      final success = await viewModel.createNoteFromImage(
        imageFile: _selectedImage!,
        title: _titleController.text.trim(),
        generateSummary: _generateSummary,
        generateFlashcards: _generateFlashcards,
      );

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Note created from image (${viewModel.wordCount} words extracted)',
            ),
          ),
        );
      }
    } else {
      // Save from PDF
      if (_selectedPdf == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a PDF file')),
        );
        return;
      }

      final success = await viewModel.createNoteFromPdf(
        pdfFile: _selectedPdf!,
        title: _titleController.text.trim(),
        generateSummary: _generateSummary,
        generateFlashcards: _generateFlashcards,
      );

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Note created from PDF (${viewModel.wordCount} words extracted)',
            ),
          ),
        );
      }
    }
  }
}
