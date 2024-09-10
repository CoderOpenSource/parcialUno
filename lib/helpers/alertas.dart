part of 'helpers.dart';

mostrarLoading(BuildContext context) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
            title: Text('Espere...'),
            content: LinearProgressIndicator(),
          ));
}

mostrarAlerta(BuildContext context, String titulo, String mensaje) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      // Usa un nombre diferente para este BuildContext para evitar confusiones
      return AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          MaterialButton(
            child: Text('Ok'),
            onPressed: () => Navigator.of(dialogContext)
                .pop(), // Usa el BuildContext del diálogo
          ),
        ],
      );
    },
  );
}
