import 'package:flutter/material.dart';

import '../../../widgets/recent_search_contacts.dart';
import '../../../ui_constants.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: defaultPadding),
      child: Column(
        children: [
          RecentSearchContacts(),
          SizedBox(height: defaultPadding),
          // you can show suggested style for search result
          SuggestedContacts()
        ],
      ),
    );
  }
}

class SuggestedContacts extends StatelessWidget {
  const SuggestedContacts({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Text(
            "Suggested",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .color!
                      .withOpacity(0.32),
                ),
          ),
        ),
        const SizedBox(height: defaultPadding),
        ...List.generate(
          demoContactsImage.length,
          (index) => ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: defaultPadding, vertical: defaultPadding / 2),
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage(demoContactsImage[index]),
            ),
            title: const Text("Jenny Wilson"),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

final List<String> demoContactsImage =
    List.generate(5, (index) => "assets/images/user_${index + 1}.png");
