import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/cofrade.dart';
import '../services/api_service.dart';
import '../services/carnet_service.dart';
import '../theme/cofradia_theme.dart';
import '../util/cofrade_foto_capture.dart';

class CofradesScreen extends StatefulWidget {
  const CofradesScreen({super.key});

  @override
  _CofradesScreenState createState() => _CofradesScreenState();
}

class _CofradesScreenState extends State<CofradesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Cofrade> _cofrades = [];
  List<String> _seccionesCatalogo = [];
  List<String> _divisionesCatalogo = [];
  List<String> _agrupacionesCatalogo = [];
  final _formKey = GlobalKey<FormState>();
  List<Cofrade> _filteredCofrades = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCofrades();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCofrades() async {
    try {
      setState(() => _isLoading = true);
      final cofradesFuture = _apiService.getCofrades();
      final seccionesFuture = _apiService.getSeccionesCatalogo();
      final divisionesFuture = _apiService.getDivisionesCatalogo();
      final agrupacionesFuture = _apiService.getAgrupacionesCatalogo();

      final cofrades = await cofradesFuture;
      final secciones = await seccionesFuture;
      final divisiones = await divisionesFuture;
      final agrupaciones = await agrupacionesFuture;
      setState(() {
        _cofrades = cofrades;
        _filteredCofrades = cofrades;
        _seccionesCatalogo = secciones;
        _divisionesCatalogo = divisiones;
        _agrupacionesCatalogo = agrupaciones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al cargar cofrades: $e');
    }
  }

  Future<void> _reloadCatalogos() async {
    final secciones = await _apiService.getSeccionesCatalogo();
    final divisiones = await _apiService.getDivisionesCatalogo();
    final agrupaciones = await _apiService.getAgrupacionesCatalogo();
    if (!mounted) return;
    setState(() {
      _seccionesCatalogo = secciones;
      _divisionesCatalogo = divisiones;
      _agrupacionesCatalogo = agrupaciones;
    });
  }

  void _filterCofrades(String query) {
    setState(() {
      _filteredCofrades = _cofrades.where((cofrade) {
        final nombre = '${cofrade.nombre} ${cofrade.apellidos}'.toLowerCase();
        final searchQuery = query.toLowerCase();
        return nombre.contains(searchQuery);
      }).toList();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CofradiaTheme.colorError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CofradiaTheme.colorExito,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<bool> _confirmDelete(String nombre) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro que desea eliminar al cofrade "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
            style: TextButton.styleFrom(
              foregroundColor: CofradiaTheme.blancoCofradia,
              backgroundColor: CofradiaTheme.rojoCofradia,
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _deleteCofrade(Cofrade cofrade) async {
    if (!await _confirmDelete('${cofrade.nombre} ${cofrade.apellidos}')) return;

    try {
      await _apiService.deleteCofrade(cofrade.id);
      _showSuccess('Cofrade eliminado con éxito');
      _loadCofrades();
    } catch (e) {
      _showError('Error al eliminar cofrade: $e');
    }
  }

  Future<void> _generarCarnet(Cofrade cofrade) async {
    try {
      print('Solicitando generación de carnet para ${cofrade.nombre}');
      // Datos al día desde Supabase (incluye foto_url recién guardada)
      final cofradeActualizado = await _apiService.getCofrade(cofrade.id);
      await CarnetService.generarCarnet(cofradeActualizado, context);
      
      print('Carnet procesado exitosamente');
    } catch (e) {
      print('Error en generación de carnet: $e');
      _showError('Error al generar carnet: $e');
    }
  }

  Future<void> _generarCarnetsMasivos() async {
    if (_filteredCofrades.isEmpty) {
      _showError('No hay cofrades para generar carnets');
      return;
    }

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generar Carnets Masivos'),
        content: Text('¿Desea generar carnets para todos los ${_filteredCofrades.length} cofrades mostrados?\n\nCada carnet se abrirá en una nueva pestaña.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generar'),
            style: TextButton.styleFrom(
              backgroundColor: CofradiaTheme.colorExito, 
              foregroundColor: CofradiaTheme.blancoCofradia,
            ),
          ),
        ],
      ),
    );

    if (confirmacion != true) return;

    try {
      print('Iniciando generación masiva de ${_filteredCofrades.length} carnets');
      
      // Generar carnets para todos los cofrades filtrados (cada uno abrirá su propia pestaña)
      for (int i = 0; i < _filteredCofrades.length; i++) {
        final actualizado = await _apiService.getCofrade(_filteredCofrades[i].id);
        await CarnetService.generarCarnet(actualizado, context);
        // Pequeña pausa para evitar sobrecargar el navegador
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      _showSuccess('Proceso completado: ${_filteredCofrades.length} carnets generados');
    } catch (e) {
      _showError('Error al generar carnets masivos: $e');
    }
  }

  void _showCofradePicture(String nombre, String? fotoUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nombre),
        content: fotoUrl != null && fotoUrl.isNotEmpty
            ? Image.network(
                fotoUrl,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  size: 100,
                  color: Colors.grey,
                ),
              )
            : const Icon(
                Icons.person,
                size: 100,
                color: Colors.grey,
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCofradiaDialog([Cofrade? cofrade]) async {
    try {
      await _reloadCatalogos();
    } catch (e) {
      _showError('No se pudieron cargar catálogos: $e');
      return;
    }

    final bool isEditing = cofrade != null;
    final nombreController = TextEditingController(text: cofrade?.nombre ?? '');
    final apellidosController = TextEditingController(text: cofrade?.apellidos ?? '');
    final telefonoController = TextEditingController(text: cofrade?.telefono ?? '');
    final emailController = TextEditingController(text: cofrade?.email ?? '');
    final fechaAltaController = TextEditingController(text: cofrade?.fechaAlta ?? '');

    // Asegurarnos de que usamos una sección válida
    String selectedSeccion = cofrade?.categoria ?? _seccionesCatalogo.first;
    if (!_seccionesCatalogo.contains(selectedSeccion)) {
      selectedSeccion = _seccionesCatalogo.first;
    }
    
    // Asegurarnos de que usamos una división válida
    String selectedDivision;
    if (cofrade?.estado != null && _divisionesCatalogo.contains(cofrade!.estado)) {
      selectedDivision = cofrade.estado;
    } else {
      selectedDivision = _divisionesCatalogo.first;
    }

    String selectedAgrupacion = cofrade?.agrupacion ?? _agrupacionesCatalogo.first;
    if (!_agrupacionesCatalogo.contains(selectedAgrupacion)) {
      selectedAgrupacion = _agrupacionesCatalogo.first;
    }

    Uint8List? nuevaFotoBytes;
    String mimeNuevaFoto = 'image/jpeg';
    var quitarFoto = false;
    final fotoUrlActual = cofrade?.fotoUrl ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final dialogWidth = constraints.maxWidth < 560 ? constraints.maxWidth : 520.0;
            return StatefulBuilder(
              builder: (context, setDialogState) {
                Future<void> elegirFoto(ImageSource source) async {
                  if (kIsWeb && source == ImageSource.camera) {
                    final bytes =
                        await captureCofradePhotoWithWebCamera(dialogContext);
                    if (!dialogContext.mounted || bytes == null) return;
                    mimeNuevaFoto = 'image/jpeg';
                    quitarFoto = false;
                    nuevaFotoBytes = bytes;
                    setDialogState(() {});
                    return;
                  }
                  final picker = ImagePicker();
                  final x = await picker.pickImage(
                    source: source,
                    maxWidth: 1200,
                    imageQuality: 85,
                  );
                  if (x == null) return;
                  final bytes = await x.readAsBytes();
                  final path = x.path.toLowerCase();
                  mimeNuevaFoto = path.endsWith('.png') ? 'image/png' : 'image/jpeg';
                  quitarFoto = false;
                  nuevaFotoBytes = bytes;
                  setDialogState(() {});
                }

                Widget previewFoto() {
                  final nombrePreview =
                      '${nombreController.text.trim()} ${apellidosController.text.trim()}'.trim();
                  if (nuevaFotoBytes != null) {
                    return CircleAvatar(
                      radius: 44,
                      backgroundImage: MemoryImage(nuevaFotoBytes!),
                    );
                  }
                  if (!quitarFoto && fotoUrlActual.isNotEmpty) {
                    return CircleAvatar(
                      radius: 44,
                      backgroundColor: CofradiaTheme.azulCofradia,
                      backgroundImage: NetworkImage(fotoUrlActual),
                      onBackgroundImageError: (_, __) {},
                      child: const SizedBox.shrink(),
                    );
                  }
                  return CircleAvatar(
                    radius: 44,
                    backgroundColor: CofradiaTheme.azulCofradia,
                    foregroundColor: CofradiaTheme.blancoCofradia,
                    child: Text(
                      nombrePreview.isNotEmpty
                          ? (nombrePreview.length >= 2
                              ? nombrePreview.substring(0, 2).toUpperCase()
                              : nombrePreview[0].toUpperCase())
                          : '?',
                      style: const TextStyle(fontSize: 22),
                    ),
                  );
                }

                return AlertDialog(
                  insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  title: Text(isEditing ? 'Editar Cofrade' : 'Nuevo Cofrade'),
                  content: SizedBox(
                    width: dialogWidth,
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                previewFoto(),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => elegirFoto(ImageSource.camera),
                                        icon: const Icon(Icons.camera_alt, size: 20),
                                        label: const Text('Tomar foto'),
                                      ),
                                      const SizedBox(height: 6),
                                      OutlinedButton.icon(
                                        onPressed: () => elegirFoto(ImageSource.gallery),
                                        icon: const Icon(Icons.photo_library_outlined, size: 20),
                                        label: Text(kIsWeb ? 'Elegir imagen' : 'Galería'),
                                      ),
                                      if (fotoUrlActual.isNotEmpty || nuevaFotoBytes != null)
                                        TextButton(
                                          onPressed: () {
                                            nuevaFotoBytes = null;
                                            quitarFoto = true;
                                            setDialogState(() {});
                                          },
                                          child: const Text('Quitar foto'),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: nombreController,
                              decoration: const InputDecoration(labelText: 'Nombre'),
                              onChanged: (_) => setDialogState(() {}),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Campo requerido' : null,
                            ),
                            TextFormField(
                              controller: apellidosController,
                              decoration: const InputDecoration(labelText: 'Apellidos'),
                              onChanged: (_) => setDialogState(() {}),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Campo requerido' : null,
                            ),
                            TextFormField(
                              controller: telefonoController,
                              decoration: const InputDecoration(labelText: 'Teléfono'),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Campo requerido' : null,
                              keyboardType: TextInputType.phone,
                            ),
                            TextFormField(
                              controller: emailController,
                              decoration: const InputDecoration(labelText: 'Email'),
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Campo requerido';
                                if (!value!.contains('@')) return 'Email inválido';
                                return null;
                              },
                              keyboardType: TextInputType.emailAddress,
                            ),
                            DropdownButtonFormField<String>(
                              value: selectedSeccion,
                              decoration: const InputDecoration(labelText: 'Sección'),
                              items: _seccionesCatalogo
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  selectedSeccion = value;
                                  setDialogState(() {});
                                }
                              },
                              validator: (value) => value == null ? 'Campo requerido' : null,
                            ),
                            DropdownButtonFormField<String>(
                              value: selectedDivision,
                              decoration: const InputDecoration(labelText: 'División'),
                              items: _divisionesCatalogo
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  selectedDivision = value;
                                  setDialogState(() {});
                                }
                              },
                              validator: (value) => value == null ? 'Campo requerido' : null,
                            ),
                            DropdownButtonFormField<String>(
                              value: selectedAgrupacion,
                              decoration: const InputDecoration(labelText: 'Agrupación'),
                              items: _agrupacionesCatalogo
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  selectedAgrupacion = value;
                                  setDialogState(() {});
                                }
                              },
                              validator: (value) => value == null ? 'Campo requerido' : null,
                            ),
                            TextFormField(
                              controller: fechaAltaController,
                              decoration: const InputDecoration(labelText: 'Fecha de Alta'),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Campo requerido' : null,
                              readOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  fechaAltaController.text =
                                      DateFormat('yyyy-MM-dd').format(date);
                                  setDialogState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (!(_formKey.currentState?.validate() ?? false)) return;

                        try {
                          if (isEditing) {
                            String fotoUrlGuardar;
                            if (quitarFoto) {
                              fotoUrlGuardar = '';
                            } else if (nuevaFotoBytes != null) {
                              fotoUrlGuardar = await _apiService.uploadCofradeFoto(
                                cofradeId: cofrade.id,
                                bytes: nuevaFotoBytes!,
                                contentType: mimeNuevaFoto,
                              );
                            } else {
                              fotoUrlGuardar = fotoUrlActual;
                            }
                            final actualizado = Cofrade(
                              id: cofrade.id,
                              nombre: nombreController.text,
                              apellidos: apellidosController.text,
                              telefono: telefonoController.text,
                              email: emailController.text,
                              categoria: selectedSeccion,
                              estado: selectedDivision,
                              agrupacion: selectedAgrupacion,
                              fechaAlta: fechaAltaController.text,
                              fotoUrl: fotoUrlGuardar,
                            );
                            await _apiService.updateCofrade(actualizado.id, actualizado);
                            _showSuccess('Cofrade actualizado con éxito');
                          } else {
                            final nuevo = Cofrade(
                              id: '',
                              nombre: nombreController.text,
                              apellidos: apellidosController.text,
                              telefono: telefonoController.text,
                              email: emailController.text,
                              categoria: selectedSeccion,
                              estado: selectedDivision,
                              agrupacion: selectedAgrupacion,
                              fechaAlta: fechaAltaController.text,
                              fotoUrl: '',
                            );
                            final created = await _apiService.createCofrade(nuevo);
                            if (nuevaFotoBytes != null) {
                              final url = await _apiService.uploadCofradeFoto(
                                cofradeId: created.id,
                                bytes: nuevaFotoBytes!,
                                contentType: mimeNuevaFoto,
                              );
                              await _apiService.updateCofrade(
                                created.id,
                                created.copyWith(fotoUrl: url),
                              );
                            }
                            _showSuccess('Cofrade creado con éxito');
                          }
                          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                          await _loadCofrades();
                        } catch (e) {
                          _showError(
                            isEditing
                                ? 'Error al actualizar cofrade: $e'
                                : 'Error al crear cofrade: $e',
                          );
                        }
                      },
                      child: Text(isEditing ? 'Actualizar' : 'Crear'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cofrades'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar cofrades',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterCofrades('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterCofrades,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredCofrades.length,
                    itemBuilder: (context, index) {
                      final cofrade = _filteredCofrades[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: GestureDetector(
                            onTap: () => _showCofradePicture(
                              '${cofrade.nombre} ${cofrade.apellidos}',
                              cofrade.fotoUrl.isNotEmpty ? cofrade.fotoUrl : null,
                            ),
                            child: CircleAvatar(
                              backgroundColor: CofradiaTheme.azulCofradia,
                              foregroundColor: CofradiaTheme.blancoCofradia,
                              backgroundImage: cofrade.fotoUrl.isNotEmpty
                                  ? NetworkImage(cofrade.fotoUrl)
                                  : null,
                              onBackgroundImageError: cofrade.fotoUrl.isNotEmpty
                                  ? (_, __) {}
                                  : null,
                              child: cofrade.fotoUrl.isNotEmpty
                                  ? null
                                  : Text(cofrade.avatar),
                            ),
                          ),
                          title: Text('${cofrade.nombre} ${cofrade.apellidos}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: ${cofrade.email}'),
                              Text('Teléfono: ${cofrade.telefono}'),
                              Text('${cofrade.categoria} - ${cofrade.estado}'),
                              if (cofrade.agrupacion.isNotEmpty) Text('Agrupación: ${cofrade.agrupacion}'),
                              Text('Fecha de alta: ${cofrade.fechaAlta}'),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: CofradiaTheme.azulCofradia),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'carnet',
                                child: Row(
                                  children: [
                                    Icon(Icons.credit_card, color: CofradiaTheme.amarilloCofradia),
                                    SizedBox(width: 8),
                                    Text('Generar Carnet'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: CofradiaTheme.rojoCofradia),
                                    SizedBox(width: 8),
                                    Text('Eliminar'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _showCofradiaDialog(cofrade);
                                  break;
                                case 'carnet':
                                  _generarCarnet(cofrade);
                                  break;
                                case 'delete':
                                  _deleteCofrade(cofrade);
                                  break;
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "carnet_masivo",
            onPressed: () => _generarCarnetsMasivos(),
            backgroundColor: CofradiaTheme.amarilloCofradia,
            foregroundColor: CofradiaTheme.azulCofradia,
            child: const Icon(Icons.credit_card),
            tooltip: 'Generar Carnets Masivos',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "agregar_cofrade",
            onPressed: () => _showCofradiaDialog(),
            backgroundColor: CofradiaTheme.rojoCofradia,
            foregroundColor: CofradiaTheme.blancoCofradia,
            child: const Icon(Icons.add),
            tooltip: 'Agregar Cofrade',
          ),
        ],
      ),
    );
  }
}
