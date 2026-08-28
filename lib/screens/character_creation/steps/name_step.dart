import 'package:flutter/material.dart';

class NameStep extends StatefulWidget {
  final String name;
  final ValueChanged<String> onNameChanged;

  const NameStep({super.key, required this.name, required this.onNameChanged});

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.name);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cómo se llama tu personaje?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre del personaje',
              border: OutlineInputBorder(),
            ),
            onChanged: widget.onNameChanged,
          ),
        ],
      ),
    );
  }
}
