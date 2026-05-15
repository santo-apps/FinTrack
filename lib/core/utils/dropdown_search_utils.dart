import 'dart:math' as math;

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class DropdownSearchUi {
  static PopupProps<T> adaptiveMenuPopup<T>({
    required BuildContext context,
    required String searchHint,
    double maxHeight = 320,
    bool showSearchBox = true,
    FlexFit fit = FlexFit.loose,
    DropdownSearchPopupItemBuilder<T>? itemBuilder,
    EmptyBuilder? emptyBuilder,
    LoadingBuilder? loadingBuilder,
    ErrorBuilder? errorBuilder,
    PopupBuilder? containerBuilder,
    ListViewProps listViewProps = const ListViewProps(),
    bool showSelectedItems = false,
    TextFieldProps? searchFieldProps,
    double elevation = 6,
    BorderRadiusGeometry borderRadius = const BorderRadius.all(
      Radius.circular(12),
    ),
  }) {
    return PopupProps.menu(
      showSearchBox: showSearchBox,
      fit: fit,
      searchDelay: Duration.zero,
      constraints: BoxConstraints(maxHeight: maxHeight),
      itemBuilder: itemBuilder,
      emptyBuilder: emptyBuilder,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      containerBuilder: containerBuilder,
      listViewProps: listViewProps,
      showSelectedItems: showSelectedItems,
      menuProps: MenuProps(
        elevation: elevation,
        borderRadius: borderRadius,
        positionCallback: (popupButtonObject, overlay) {
          return adaptiveMenuPosition(
            context: context,
            popupButtonObject: popupButtonObject,
            overlay: overlay,
            desiredPopupHeight: maxHeight,
          );
        },
      ),
      searchFieldProps: searchFieldProps ??
          TextFieldProps(
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
    );
  }

  static RelativeRect adaptiveMenuPosition({
    required BuildContext context,
    required RenderBox popupButtonObject,
    required RenderBox overlay,
    required double desiredPopupHeight,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final topSafe = mediaQuery.padding.top;
    final bottomSafe = math.max(
      mediaQuery.padding.bottom,
      mediaQuery.viewPadding.bottom,
    );
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    final topLeft = popupButtonObject.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );
    final bottomLeft = popupButtonObject.localToGlobal(
      popupButtonObject.size.bottomLeft(Offset.zero),
      ancestor: overlay,
    );
    final bottomRight = popupButtonObject.localToGlobal(
      popupButtonObject.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );

    const edgeGap = 8.0;
    const minPopupHeight = 96.0;

    final usableTop = topSafe + edgeGap;
    final usableBottom =
        overlay.size.height - keyboardHeight - bottomSafe - edgeGap;

    final availableBelow = usableBottom - bottomLeft.dy;
    final availableAbove = topLeft.dy - usableTop;

    final bestAvailable = math.max(availableBelow, availableAbove);
    final popupHeight = math.max(
      minPopupHeight,
      math.min(desiredPopupHeight, bestAvailable),
    );

    final openUpward =
        availableBelow < math.min(240, desiredPopupHeight * 0.7) &&
            availableAbove > availableBelow;

    final left = bottomLeft.dx;
    final right = overlay.size.width - bottomRight.dx;
    final top = openUpward
        ? math.max(usableTop, topLeft.dy - popupHeight)
        : math.min(bottomLeft.dy, usableBottom - popupHeight);
    final bottom = math.max(0.0, overlay.size.height - (top + popupHeight));

    return RelativeRect.fromLTRB(
      left,
      top,
      right,
      bottom,
    );
  }
}
