import 'package:flutter/material.dart';

class DoublePasswordField extends StatefulWidget {
  final TextEditingController controller1, controller2;
  final String label1, label2;

  const DoublePasswordField({
    super.key,
    required this.controller1,
    required this.controller2,
    required this.label1,
    required this.label2,
  });

  @override
  _DoublePasswordFieldState createState() => _DoublePasswordFieldState();
}

class _DoublePasswordFieldState extends State<DoublePasswordField> {
  bool _obscure1 = true;
  bool _obscure2 = true;

  InputDecoration _inputDecoration(String label, String hintText,
      bool isObscure, VoidCallback toggleObscure) {
    return InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        icon: Icon(isObscure ? Icons.visibility : Icons.visibility_off),
        onPressed: toggleObscure,
      ),
      labelStyle: const TextStyle(color: Color.fromARGB(255, 8, 45, 101)),
      hintText: hintText,
      hintStyle: const TextStyle(color: Color.fromARGB(255, 8, 45, 101)),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Color.fromARGB(255, 8, 45, 101)),
        borderRadius: BorderRadius.circular(20),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color.fromARGB(255, 8, 45, 101)),
        borderRadius: BorderRadius.circular(20),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color.fromARGB(255, 8, 45, 101)),
        borderRadius: BorderRadius.circular(20),
      ),
      filled: true,
      fillColor: Colors.white,
      focusColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // ¡Eliminamos el Expanded!
        TextField(
          controller: widget.controller1,
          obscureText: _obscure1,
          decoration: _inputDecoration(
              widget.label1, 'Ingresa tu Contraseña:', _obscure1, () {
            setState(() {
              _obscure1 = !_obscure1;
            });
          }),
        ),
        const SizedBox(height: 10),
        // ¡Eliminamos el Expanded!
        TextField(
          controller: widget.controller2,
          obscureText: _obscure2,
          decoration: _inputDecoration(
              widget.label2, 'Por favor confirma tu contraseña', _obscure2, () {
            setState(() {
              _obscure2 = !_obscure2;
            });
          }),
        ),
      ],
    );
  }
}
