import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/secret_keyboard/secret_input.dart';
import 'package:flutter/material.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader(
      {super.key,
      this.label,
      required this.searching,
      required this.searchFocus,
      required this.searchController,
      required this.onSearchIconPressed,
      required this.onCloseIconPressed});

  final Widget? label;
  final FocusNode searchFocus;
  final bool searching;
  final TextEditingController searchController;

  final Function onSearchIconPressed;
  final Function onCloseIconPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Colors.grey[200] ?? Colors.grey))),
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (label != null && !searching) label!,
          if (searching)
            Expanded(
              child: TextFormField(
                focusNode: searchFocus,
                controller: searchController,
                onTap: () {
                  openSecretInput(
                      context: context, controller: searchController);
                },
                keyboardType: TextInputType.none,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  fillColor: Colors.white,
                  hintStyle: TextStyle(
                    color: contentColorLightTheme.withOpacity(0.64),
                  ),
                ),
              ),
            )
          else
            Container(),
          if (searching)
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 30,
              ),
              onPressed: () {
                onCloseIconPressed();
              },
            )
          else
            IconButton(
              icon: const Icon(
                Icons.search,
                size: 30,
              ),
              onPressed: () {
                onSearchIconPressed();
              },
            ),
        ],
      ),
    );
  }
}
