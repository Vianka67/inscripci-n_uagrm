import 'package:flutter/material.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';

/// Un contenedor maestro para dotar a las tablas del sistema con la sombra,
/// bordes redondeados y fondo blanco uniforme.
class StandardTableContainer extends StatelessWidget {
  final Widget child;

  const StandardTableContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

/// Una fila de encabezado genérica con fondo Navy Dark y texto blanco.
/// Especialmente útil para pseudo-tablas hechas con ListView o listados manuales.
class StandardTableHeader extends StatelessWidget {
  final List<Widget> children;

  const StandardTableHeader({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: UAGRMTheme.sidebarDeep, // Navy oscuro (#0B1A2B)
      ),
      child: Row(
        children: children,
      ),
    );
  }
}

/// Helper para generar Textos de Cabecera con tipografía en negrita y blanca
class StandardHeaderCell extends StatelessWidget {
  final String text;
  final TextAlign textAlign;

  const StandardHeaderCell(this.text, {super.key, this.textAlign = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: Colors.white,
      ),
    );
  }
}

/// Helper para crear TableRow (nativo de Flutter `Table`) con fondo Navy Dark.
TableRow buildStandardTableRowHeader({required List<String> labels, List<TextAlign>? aligns}) {
  return TableRow(
    decoration: const BoxDecoration(
      color: UAGRMTheme.sidebarDeep,
    ),
    children: labels.asMap().entries.map((entry) {
      final i = entry.key;
      final text = entry.value;
      final align = (aligns != null && i < aligns.length) ? aligns[i] : TextAlign.left;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: StandardHeaderCell(text, textAlign: align),
      );
    }).toList(),
  );
}

/// Envoltura uniforme para el componente DataRow y DataTable nativo de Flutter.
class StandardDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double columnSpacing;
  final double? minWidth;
  final WidgetStateProperty<Color?>? headingRowColor;
  final double dividerThickness;

  const StandardDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.columnSpacing = 24,
    this.minWidth,
    this.headingRowColor,
    this.dividerThickness = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return StandardTableContainer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget table = DataTable(
            headingRowColor: headingRowColor ?? WidgetStateProperty.resolveWith((states) => UAGRMTheme.sidebarDeep),
            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            dividerThickness: dividerThickness,
            columnSpacing: columnSpacing,
            columns: columns,
            rows: rows,
          );

          if (minWidth != null) {
            table = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minWidth!),
                child: table,
              ),
            );
          }

          return table;
        },
      ),
    );
  }
}
