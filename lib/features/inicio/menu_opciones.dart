import 'package:flutter/material.dart';

/// Botones del menú principal (plan 14A §2). Orden fijo: nunca se reordena.
enum MenuOpcion {
  comunicar(
    titulo: 'Comunicar',
    descripcion: 'Arma frases con pictogramas',
    icono: Icons.chat_bubble,
    categoria: 'clima',
    ruta: '/home/comunicar',
  ),
  aprender(
    titulo: 'Aprender',
    descripcion: 'Juegos de memoria, cuentos y dibujo',
    icono: Icons.menu_book,
    categoria: 'acciones',
    ruta: '/home/aprender',
  ),
  rutinas(
    titulo: 'Rutinas',
    descripcion: 'Mi horario y primero y luego',
    icono: Icons.schedule,
    categoria: 'lugares',
    ruta: '/home/rutinas',
  ),
  ajustes(
    titulo: 'Ajustes',
    descripcion: 'Voz, colores y modo calma',
    icono: Icons.settings,
    categoria: 'objetos',
    ruta: '/home/ajustes',
  ),
  padre(
    titulo: 'Modo padre',
    descripcion: 'Solo para adultos, con código',
    icono: Icons.lock,
    categoria: 'comida',
    ruta: '/padre',
  );

  const MenuOpcion({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.categoria,
    required this.ruta,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;

  /// Clave de `coloresCategorias`: AA garantizado en las 7 paletas.
  final String categoria;
  final String ruta;
}
