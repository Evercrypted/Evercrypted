import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_text_controller.dart';
import 'package:evercrypted/widgets/evercrypted_text_field.dart';
import 'package:flutter/material.dart';

class SearchHeader extends StatefulWidget {
  const SearchHeader(
      {super.key,
      this.label,
      required this.searching,
      required this.searchController,
      required this.onCloseIconPressed,
      this.onTapHandler,
      this.hintText});

  final Widget? label;
  final bool searching;
  final EvercryptedTextController searchController;
  final Function? onTapHandler;
  final Function onCloseIconPressed;
  final String? hintText;

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  bool hasText = false;

  @override
  void initState() {
    super.initState();
    hasText = widget.searchController.text.isNotEmpty;
    widget.searchController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final currentHasText = widget.searchController.text.isNotEmpty;
    if (currentHasText != hasText) {
      setState(() {
        hasText = currentHasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding / 2,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: SizedBox(
                  height: 48,
                  child: EvercryptedTextField(
                    controller: widget.searchController,
                    maxLines: 1,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hintText: widget.hintText ?? 'Search...',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (hasText)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: InkWell(
                  child: const Icon(
                    Icons.close,
                    size: 30,
                  ),
                  onTap: () {
                    widget.onCloseIconPressed();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
