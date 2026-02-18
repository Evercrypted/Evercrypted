import 'package:evercrypted/widgets/material_icon_registry.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

/// Result returned by the avatar editor when the user saves.
class AvatarEditResult {
  final String? name;
  final Color? color;
  final int? iconCodePoint; // Material icon code point, or null to clear icon

  AvatarEditResult({this.name, this.color, this.iconCodePoint});
}

/// A reusable bottom sheet for editing avatar (color + icon) and optionally a name.
class AvatarEditorBottomSheet extends StatefulWidget {
  /// If true, shows a name text field.
  final bool showNameField;

  /// Initial name.
  final String? initialName;

  /// Initial avatar color.
  final Color? initialColor;

  /// Initial avatar icon code point.
  final int? initialIconCodePoint;

  /// Label for the name field.
  final String nameLabel;

  const AvatarEditorBottomSheet({
    super.key,
    this.showNameField = true,
    this.initialName,
    this.initialColor,
    this.initialIconCodePoint,
    this.nameLabel = 'Name',
  });

  @override
  State<AvatarEditorBottomSheet> createState() =>
      _AvatarEditorBottomSheetState();

  /// Convenience method to show the bottom sheet and return the result.
  static Future<AvatarEditResult?> show(
    BuildContext context, {
    bool showNameField = true,
    String? initialName,
    Color? initialColor,
    int? initialIconCodePoint,
    String nameLabel = 'Name',
  }) {
    return showModalBottomSheet<AvatarEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AvatarEditorBottomSheet(
        showNameField: showNameField,
        initialName: initialName,
        initialColor: initialColor,
        initialIconCodePoint: initialIconCodePoint,
        nameLabel: nameLabel,
      ),
    );
  }
}

class _AvatarEditorBottomSheetState extends State<AvatarEditorBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _iconSearchController;
  late Color _selectedColor;
  int? _selectedIconCodePoint;
  Map<String, IconData> _filteredIcons = MaterialIconRegistry.icons;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _iconSearchController = TextEditingController();
    _selectedColor = widget.initialColor ?? Colors.blueGrey;
    _selectedIconCodePoint = widget.initialIconCodePoint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconSearchController.dispose();
    super.dispose();
  }

  void _onIconSearchChanged(String query) {
    setState(() {
      _filteredIcons = MaterialIconRegistry.search(query);
    });
  }

  void _openColorPicker() async {
    Color pickerColor = _selectedColor;
    final bool picked = await ColorPicker(
      color: pickerColor,
      onColorChanged: (Color color) => pickerColor = color,
      width: 36,
      height: 36,
      borderRadius: 4,
      spacing: 4,
      runSpacing: 4,
      wheelDiameter: 155,
      heading: Text(
        'Select color',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subheading: Text(
        'Select color shade',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        longPressMenu: true,
      ),
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: false,
        ColorPickerType.wheel: true,
      },
    ).showPickerDialog(
      context,
      transitionBuilder: (BuildContext context, Animation<double> a1,
          Animation<double> a2, Widget widget) {
        final double curvedValue =
            Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: widget,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
    if (picked) {
      setState(() {
        _selectedColor = pickerColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final iconEntries = _filteredIcons.entries.toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar preview
          GestureDetector(
            onTap: _openColorPicker,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: _selectedColor,
              child: _selectedIconCodePoint != null
                  ? Icon(
                      MaterialIconRegistry.iconDataFromCodePoint(
                          _selectedIconCodePoint!),
                      color: Colors.white,
                      size: 44,
                    )
                  : (_nameController.text.isNotEmpty
                      ? Text(
                          _nameController.text.length > 2
                              ? _nameController.text
                                  .substring(0, 2)
                                  .toUpperCase()
                              : _nameController.text.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const Icon(Icons.person,
                          color: Colors.white, size: 44)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap avatar to change color',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Name field (optional)
          if (widget.showNameField) ...[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: widget.nameLabel,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
          ],

          // Icon search field
          TextField(
            controller: _iconSearchController,
            decoration: InputDecoration(
              hintText: 'Search icons...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _iconSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _iconSearchController.clear();
                        _onIconSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            onChanged: _onIconSearchChanged,
          ),
          const SizedBox(height: 8),

          // Icon grid label + count
          Row(
            children: [
              Text(
                'Choose an icon',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              Text(
                '${iconEntries.length} icons',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Icon grid (scrollable)
          SizedBox(
            height: 210,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: iconEntries.length + 1, // +1 for "none" option
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Clear icon option
                  final bool isSelected = _selectedIconCodePoint == null;
                  return Tooltip(
                    message: 'No icon',
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedIconCodePoint = null),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withAlpha((255 * 0.3).round())
                              : Colors.grey.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: _selectedColor, width: 2)
                              : null,
                        ),
                        child: const Icon(Icons.block, color: Colors.grey),
                      ),
                    ),
                  );
                }
                final entry = iconEntries[index - 1];
                final iconData = entry.value;
                final iconName = entry.key;
                final bool isSelected =
                    _selectedIconCodePoint == iconData.codePoint;
                return Tooltip(
                  message: iconName,
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _selectedIconCodePoint = iconData.codePoint),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withAlpha((255 * 0.3).round())
                            : Colors.grey.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: _selectedColor, width: 2)
                            : null,
                      ),
                      child: Icon(
                        iconData,
                        color:
                            isSelected ? _selectedColor : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      AvatarEditResult(
                        name: widget.showNameField
                            ? _nameController.text.trim()
                            : null,
                        color: _selectedColor,
                        iconCodePoint: _selectedIconCodePoint,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
