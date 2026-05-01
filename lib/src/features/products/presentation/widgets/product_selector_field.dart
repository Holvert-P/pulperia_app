import 'package:flutter/material.dart';

class ProductSelectorField<T> extends StatelessWidget {
  const ProductSelectorField({
    super.key,
    required this.label,
    required this.icon,
    required this.valueLabel,
    required this.options,
    required this.optionTitle,
    required this.onSelected,
    this.optionSubtitle,
    this.optionSearchText,
    this.enabled = true,
    this.emptyText = 'No hay opciones disponibles',
  });

  final String label;
  final IconData icon;
  final String? valueLabel;
  final List<T> options;
  final String Function(T item) optionTitle;
  final String? Function(T item)? optionSubtitle;
  final String Function(T item)? optionSearchText;
  final ValueChanged<T> onSelected;
  final bool enabled;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _openSelector(context) : null,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.expand_more),
          enabled: enabled,
        ),
        child: Text(
          valueLabel?.isNotEmpty == true ? valueLabel! : 'Seleccionar',
          style: TextStyle(
            color: valueLabel?.isNotEmpty == true
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _openSelector(BuildContext context) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _SelectorSheet<T>(
        title: label,
        options: options,
        optionTitle: optionTitle,
        optionSubtitle: optionSubtitle,
        optionSearchText: optionSearchText,
        emptyText: emptyText,
      ),
    );
    if (selected != null) {
      onSelected(selected);
    }
  }
}

class _SelectorSheet<T> extends StatefulWidget {
  const _SelectorSheet({
    required this.title,
    required this.options,
    required this.optionTitle,
    required this.optionSubtitle,
    required this.optionSearchText,
    required this.emptyText,
  });

  final String title;
  final List<T> options;
  final String Function(T item) optionTitle;
  final String? Function(T item)? optionSubtitle;
  final String Function(T item)? optionSearchText;
  final String emptyText;

  @override
  State<_SelectorSheet<T>> createState() => _SelectorSheetState<T>();
}

class _SelectorSheetState<T> extends State<_SelectorSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options.where((item) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;
      final title = widget.optionTitle(item).toLowerCase();
      final subtitle = widget.optionSubtitle?.call(item)?.toLowerCase() ?? '';
      final searchText = widget.optionSearchText?.call(item).toLowerCase() ?? '';
      return title.contains(query) ||
          subtitle.contains(query) ||
          searchText.contains(query);
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text(widget.emptyText))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final subtitle = widget.optionSubtitle?.call(item);
                          return ListTile(
                            title: Text(widget.optionTitle(item)),
                            subtitle: subtitle == null || subtitle.isEmpty
                                ? null
                                : Text(subtitle),
                            onTap: () => Navigator.of(context).pop(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
