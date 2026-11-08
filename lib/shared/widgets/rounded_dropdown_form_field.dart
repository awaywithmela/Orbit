import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class RoundedDropdownFormField<T> extends StatefulWidget {
  const RoundedDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.decoration,
    this.menuMaxHeight,
    this.itemHeight,
    this.menuWidth,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;
  final double? menuMaxHeight;
  final double? itemHeight;
  final double? menuWidth;

  @override
  State<RoundedDropdownFormField<T>> createState() =>
      _RoundedDropdownFormFieldState<T>();
}

class _RoundedDropdownFormFieldState<T>
    extends State<RoundedDropdownFormField<T>> {
  var _menuOpen = false;

  DropdownMenuItem<T>? get _selectedItem {
    for (final item in widget.items) {
      if (item.value == widget.value) return item;
    }
    return null;
  }

  Future<void> _showDropdown() async {
    if (widget.onChanged == null || _menuOpen) return;

    await Scrollable.ensureVisible(
      context,
      alignment: .16,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final field = context.findRenderObject() as RenderBox;
    final fieldTopLeft = field.localToGlobal(Offset.zero, ancestor: overlay);
    final availableWidth = overlay.size.width;
    final menuWidth =
        widget.menuWidth ??
        (availableWidth - 64).clamp(280.0, 520.0).toDouble();
    final left = (availableWidth - menuWidth) / 2;
    final top = fieldTopLeft.dy + field.size.height + 10;

    setState(() => _menuOpen = true);
    final selected = await showMenu<T>(
      context: context,
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      constraints: BoxConstraints(
        minWidth: menuWidth,
        maxWidth: menuWidth,
        maxHeight: widget.menuMaxHeight ?? 320,
      ),
      position: RelativeRect.fromLTRB(
        left,
        top,
        availableWidth - left - menuWidth,
        overlay.size.height - top,
      ),
      items: [
        for (final item in widget.items)
          PopupMenuItem<T>(
            value: item.value,
            enabled: item.enabled,
            height: widget.itemHeight ?? 52,
            onTap: item.onTap,
            child: Center(
              child: DefaultTextStyle.merge(
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.text,
                  fontWeight: item.value == widget.value
                      ? FontWeight.w700
                      : FontWeight.w700,
                ),
                child: item.child,
              ),
            ),
          ),
      ],
    );

    if (!mounted) return;
    setState(() => _menuOpen = false);
    if (selected != null) widget.onChanged?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    final leadingIcon = widget.decoration.prefixIcon;
    final theme = Theme.of(context);
    final label = widget.decoration.labelText;

    return Semantics(
      label: label,
      value: widget.value?.toString(),
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('roundedDropdownButton'),
          onTap: _showDropdown,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _menuOpen ? AppColors.blue : AppColors.border,
                width: _menuOpen ? 1.8 : 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1438BFFF),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.chip,
                      shape: BoxShape.circle,
                    ),
                    child: IconTheme.merge(
                      data: const IconThemeData(
                        color: AppColors.blue,
                        size: 22,
                      ),
                      child: leadingIcon,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (label != null) ...[
                        Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .8,
                          ),
                        ),
                        const SizedBox(height: 1),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: DefaultTextStyle.merge(
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                              child:
                                  _selectedItem?.child ??
                                  Text(widget.decoration.hintText ?? ''),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _menuOpen ? .5 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: AppColors.chip,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.softText,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
