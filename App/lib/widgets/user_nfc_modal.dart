import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import 'dart:async';
import '../models/user.dart';

class UserNfcModal extends StatefulWidget {
  final User user;
  final VoidCallback onSuccess;

  const UserNfcModal({
    super.key,
    required this.user,
    required this.onSuccess,
  });

  @override
  State<UserNfcModal> createState() => _UserNfcModalState();
}

class _UserNfcModalState extends State<UserNfcModal> {
  bool _isScanning = false;
  String? _detectedUuid;
  String? _errorMessage;
  String? _successMessage;
  bool _manualEntry = false;
  late TextEditingController _manualController;
  String? _pairToken;
  Timer? _pairingTimer;

  @override
  void initState() {
    super.initState();
    _manualController = TextEditingController();
  }

  @override
  void dispose() {
    _pairingTimer?.cancel();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Associar Cartão NFC',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Usuário: ${widget.user.name}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _successMessage!,
                  style: TextStyle(color: Colors.green.shade900),
                ),
              ),
            const SizedBox(height: 16),
            _isScanning
                ? Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text(
                        'Aguardando leitura do cartão NFC...',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : _detectedUuid == null
                    ? Column(
                        children: [
                          const Icon(
                            Icons.nfc,
                            size: 64,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aproxime um cartão NFC do dispositivo',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Observação: integre um pacote NFC nativo (ex: nfc_manager)\npara capturar UUID automaticamente.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          if (!_manualEntry)
                            ElevatedButton.icon(
                              onPressed: _startScanning,
                              icon: const Icon(Icons.nfc_rounded),
                              label: const Text('Iniciar Leitura'),
                            ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _manualEntry = !_manualEntry;
                                if (_manualEntry) {
                                  _manualController.text = '';
                                }
                              });
                            },
                            child: Text(_manualEntry ? 'Cancelar entrada manual' : 'Inserir UUID manualmente'),
                          ),
                          if (_manualEntry)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _manualController,
                                    decoration: const InputDecoration(
                                      labelText: 'UUID do cartão NFC',
                                      hintText: 'Cole o UUID aqui',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      final val = _manualController.text.trim();
                                      if (val.isEmpty) {
                                        setState(() {
                                          _errorMessage = 'Informe o UUID manualmente.';
                                        });
                                        return;
                                      }
                                      setState(() {
                                        _detectedUuid = val;
                                        _isScanning = false;
                                        _manualEntry = false;
                                        _errorMessage = null;
                                      });
                                    },
                                    child: const Text('Confirmar UUID'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    : Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 64,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 16),
                          const Text('UUID Detectado:'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              _detectedUuid!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _detectedUuid == null ? null : _confirmAndLink,
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startScanning() async {
    // Start pairing flow: request pair token from backend and poll status.
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _detectedUuid = null;
      _successMessage = null;
    });

    try {
      final resp = await NfcService.startPairing(widget.user.cpf);
      final token = resp['pair_token'];
      setState(() {
        _pairToken = token;
      });

      // Start polling every 2 seconds
      _pairingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        try {
          final status = await NfcService.getPairStatus(_pairToken!);
          final vinculado = status['vinculado'] as bool? ?? false;
          final expired = status['expired'] as bool? ?? false;

          if (vinculado) {
            // Update UI with linked UUID
            final user = status['user'];
            final uuid = user != null ? user['nfc_card_uuid'] as String? : null;
            setState(() {
              _detectedUuid = uuid;
              _successMessage = 'Cartão vinculado com sucesso!';
              _isScanning = false;
            });
            _pairingTimer?.cancel();
            widget.onSuccess();
            // Close modal after short delay
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) Navigator.pop(context);
          } else if (expired) {
            setState(() {
              _errorMessage = 'Sessão de pareamento expirada. Tente novamente.';
              _isScanning = false;
            });
            _pairingTimer?.cancel();
          }
        } catch (e) {
          // ignore transient polling errors but show message
          setState(() {
            _errorMessage = 'Erro ao consultar status de pareamento.';
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isScanning = false;
      });
    }
  }

  Future<void> _confirmAndLink() async {
    if (_detectedUuid == null) return;

    try {
      // Vincular o UUID ao usuário
      await NfcService.linkNfcToUser(
        _detectedUuid!,
        widget.user.cpf,
      );

      setState(() {
        _successMessage = 'Cartão NFC vinculado com sucesso!';
      });

      // Esperar um pouco e fechar o modal
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        widget.onSuccess();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }
}
