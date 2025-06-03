import 'package:evercrypted/screens/activation/components/hero_card.dart';
import 'package:flutter/material.dart';

class ActivationMainScreen extends StatefulWidget {
  const ActivationMainScreen({super.key});
  static const routeName = '/activation-main-screen';

  @override
  State<ActivationMainScreen> createState() => _ActivationMainScreenState();
}

class _ActivationMainScreenState extends State<ActivationMainScreen> {
  final CarouselController controller = CarouselController(initialItem: 1);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Evercrypted Lifetime License'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ),
      body: ListView(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 300),
            child: CarouselView.weighted(
              controller: controller,
              itemSnapping: true,
              flexWeights: const <int>[1, 7, 1],
              children: ImgFlow.values.map((ImgFlow image) {
                return HeroLayoutCard(imageInfo: image);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

enum ImgFlow {
  image0('The Flow', 'Sponsored | Season 1 Now Streaming',
      'content_based_color_scheme_1.png'),
  image1(
    'Through the Pane',
    'Sponsored | Season 1 Now Streaming',
    'content_based_color_scheme_2.png',
  ),
  image2('Iridescence', 'Sponsored | Season 1 Now Streaming',
      'content_based_color_scheme_3.png'),
  image3('Sea Change', 'Sponsored | Season 1 Now Streaming',
      'content_based_color_scheme_4.png'),
  image4('Blue Symphony', 'Sponsored | Season 1 Now Streaming',
      'content_based_color_scheme_5.png'),
  image5('When It Rains', 'Sponsored | Season 1 Now Streaming',
      'content_based_color_scheme_6.png');

  const ImgFlow(this.title, this.subtitle, this.url);
  final String title;
  final String subtitle;
  final String url;
}
