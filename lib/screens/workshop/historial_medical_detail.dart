import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/screens/workshop/historial_medical.dart';

class MedicalHistoryDetailScreen extends StatelessWidget {
  final MedicalHistory history;

  MedicalHistoryDetailScreen({required this.history});

  Future<Doctor> _fetchDoctor(int doctorId) async {
    final response = await http.get(
      Uri.parse('http://161.35.16.6/usuarios/doctors/$doctorId/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Doctor.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load doctor');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Historial Médico'),
        backgroundColor: Color.fromARGB(255, 43, 29, 45),
      ),
      body: FutureBuilder<Doctor>(
        future: _fetchDoctor(history.doctor),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(
                child: Text('No hay detalles del doctor disponibles.'));
          } else {
            final doctor = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fecha: ${history.date}',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Síntomas: ${history.symptoms}',
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Diagnóstico: ${history.diagnosis}',
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Tratamiento: ${history.treatment}',
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Notas: ${history.notes}',
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Fecha de seguimiento: ${history.followUpDate}',
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  Text(
                      'Doctor: ${doctor.user.firstName} ${doctor.user.lastName}',
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrescriptionDetailScreen(
                              prescriptionId: history.prescription),
                        ),
                      );
                    },
                    child: Text('Ver Receta'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class PrescriptionDetailScreen extends StatelessWidget {
  final int prescriptionId;

  PrescriptionDetailScreen({required this.prescriptionId});

  Future<Prescription> _fetchPrescription() async {
    final response = await http.get(
      Uri.parse(
          'http://192.168.0.15/prescriptions/prescriptions/$prescriptionId/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Prescription.fromJson(
          json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load prescription');
    }
  }

  Future<Doctor> _fetchDoctor(int doctorId) async {
    final response = await http.get(
      Uri.parse('http://192.168.0.15/usuarios/doctors/$doctorId/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Doctor.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load doctor');
    }
  }

  Future<Patient> _fetchPatient(int patientId) async {
    final response = await http.get(
      Uri.parse('http://192.168.0.15/usuarios/patients/$patientId/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Patient.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load patient');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de la Receta'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<Prescription>(
        future: _fetchPrescription(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(
                child: Text('No hay detalles de la receta disponibles.'));
          } else {
            final prescription = snapshot.data!;
            return FutureBuilder<Doctor>(
              future: _fetchDoctor(prescription.doctor),
              builder: (context, doctorSnapshot) {
                if (doctorSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (doctorSnapshot.hasError) {
                  return Center(child: Text('Error: ${doctorSnapshot.error}'));
                } else if (!doctorSnapshot.hasData) {
                  return Center(
                      child: Text('No hay detalles del doctor disponibles.'));
                } else {
                  final doctor = doctorSnapshot.data!;
                  return FutureBuilder<Patient>(
                    future: _fetchPatient(prescription.patient),
                    builder: (context, patientSnapshot) {
                      if (patientSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (patientSnapshot.hasError) {
                        return Center(
                            child: Text('Error: ${patientSnapshot.error}'));
                      } else if (!patientSnapshot.hasData) {
                        return Center(
                            child: Text(
                                'No hay detalles del paciente disponibles.'));
                      } else {
                        final patient = patientSnapshot.data!;
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fecha: ${prescription.date}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              SizedBox(height: 8),
                              Text(
                                  'Paciente: ${patient.user.firstName} ${patient.user.lastName}',
                                  style: TextStyle(fontSize: 16)),
                              SizedBox(height: 8),
                              Text(
                                  'Doctor: ${doctor.user.firstName} ${doctor.user.lastName}',
                                  style: TextStyle(fontSize: 16)),
                              SizedBox(height: 16),
                              Text('Medicamentos:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              ...prescription.medications
                                  .map((medication) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0),
                                        child: Text(
                                          '${medication.medicationName} - ${medication.dosage}\n'
                                          'Frecuencia: ${medication.frequency}\n'
                                          'Duración: ${medication.duration}\n'
                                          'Instrucciones: ${medication.instructions}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      )),
                            ],
                          ),
                        );
                      }
                    },
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}

class Prescription {
  final String date;
  final int patient;
  final int doctor;
  final List<Medication> medications;

  Prescription({
    required this.date,
    required this.patient,
    required this.doctor,
    required this.medications,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      date: json['date'],
      patient: json['patient'],
      doctor: json['doctor'],
      medications: (json['medications'] as List)
          .map((medication) => Medication.fromJson(medication))
          .toList(),
    );
  }
}

class Medication {
  final String medicationName;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;

  Medication({
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      medicationName: json['medication_name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      duration: json['duration'],
      instructions: json['instructions'],
    );
  }
}

class Doctor {
  final User user;
  final String specialty;

  Doctor({required this.user, required this.specialty});

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      user: User.fromJson(json['user']),
      specialty: json['specialty'],
    );
  }
}

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String userType;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      userType: json['user_type'],
    );
  }
}

class Patient {
  final User user;

  Patient({required this.user});

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      user: User.fromJson(json['user']),
    );
  }
}
