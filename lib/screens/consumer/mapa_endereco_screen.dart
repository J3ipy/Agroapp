import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';

class MapaEnderecoScreen extends StatefulWidget {
  const MapaEnderecoScreen({super.key});

  @override
  State<MapaEnderecoScreen> createState() => _MapaEnderecoScreenState();
}

class _MapaEnderecoScreenState extends State<MapaEnderecoScreen> {
  GoogleMapController? _mapController;
  LatLng? _localizacaoAtual;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pegarLocalizacao();
  }

  Future<void> _pegarLocalizacao() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Serviço de localização desativado
      setState(() => _loading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _loading = false);
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _localizacaoAtual = LatLng(position.latitude, position.longitude);
      _loading = false;
    });

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_localizacaoAtual!, 15));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Endereço')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _localizacaoAtual == null
          ? const Center(child: Text('Não foi possível obter a localização.'))
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _localizacaoAtual ?? const LatLng(-10.9472, -37.0731), // Aracaju como fallback
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            onCameraMove: (CameraPosition position) {
              _localizacaoAtual = position.target;
            },
          ),
          const Center(
            child: Icon(Icons.location_on, size: 50, color: kDangerColor), // Pino fixo no meio
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)
              ),
              onPressed: () {
                // Aqui nós retornaríamos a latitude e longitude para o carrinho
                Navigator.pop(context, _localizacaoAtual);
              },
              child: const Text('CONFIRMAR LOCAL DE ENTREGA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}