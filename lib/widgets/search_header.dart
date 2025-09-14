import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_text_controller.dart';
import 'package:evercrypted/widgets/evercrypted_text_field.dart';
import 'package:flutter/material.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader(
      {super.key,
      this.label,
      required this.searching,
      required this.searchFocus,
      required this.searchController,
      required this.onSearchIconPressed,
      required this.onCloseIconPressed,
      required this.onTapHandler});

  final Widget? label;
  final FocusNode searchFocus;
  final bool searching;
  final EvercryptedTextController searchController;
  final Function onTapHandler;
  final Function onSearchIconPressed;
  final Function onCloseIconPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
      ),
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (label != null && !searching) label!,
          if (searching)
            Expanded(
              child: EvercryptedTextField(
                controller: searchController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                ),
              ),
            )
          else
            Container(),
          if (searching)
            InkWell(
              child: const Icon(
                Icons.close,
                size: 30,
              ),
              onTap: () {
                onCloseIconPressed();
              },
            )
          else
            InkWell(
              child: const Icon(
                Icons.search,
                size: 30,
              ),
              onTap: () {
                onSearchIconPressed();
              },
            ),
        ],
      ),
    );
  }
}
