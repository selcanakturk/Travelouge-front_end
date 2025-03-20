import 'package:flutter/material.dart';

class AddRouteScreen extends StatefulWidget {
  @override
  _AddRouteScreenState createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Yeni Rota Ekle",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Başlık"),
                validator: (value) => value!.isEmpty ? "Başlık girin" : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Açıklama"),
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: "Konum"),
              ),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: "Tarih"),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    _dateController.text =
                        "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      "title": _titleController.text,
                      "description": _descriptionController.text,
                      "location": _locationController.text,
                      "date": _dateController.text,
                      "image": "https://source.unsplash.com/300x200/?travel"
                    });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child:
                    const Text("Ekle", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
