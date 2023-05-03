import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

import '../../../ui_constants.dart';

const allowedForQueue = [];

showQueuedNotification() {
  showSimpleNotification(
      const Text(
        'Could not connect to server, this action will be queued and will be sent when connection is back.',
        style: TextStyle(color: Colors.white),
      ),
      background: secondaryColor);
}
