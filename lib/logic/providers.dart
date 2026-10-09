import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user.dart';
import '../data/models/address_card.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/cards_repository.dart';
import '../data/local/token_storage.dart';
import '../data/local/settings_storage.dart';

// ─── Shell ───────────────────────────────────────────────────────────────────

/// Shared with the outer [AppShell] Scaffold so nested screens (Home, Cards)
/// can open its Drawer, which must live on the outer Scaffold to paint above
/// the floating bottom nav bar.
final scaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});

// ─── Repositories ─────────────────────────────────────────────────────────────

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());
final cardsRepositoryProvider =
    Provider<CardsRepository>((ref) => CardsRepository());

// ─── Auth State ────────────────────────────────────────────────────────────────

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith(
          {AppUser? user,
          bool? isLoading,
          String? error,
          bool clearUser = false}) =>
      AuthState(
        user: clearUser ? null : user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    if (!await TokenStorage.hasToken()) {
      state = const AuthState();
      return;
    }
    try {
      final user = await _repo.getMe();
      if (user == null) {
        // The server rejected the token (expired / invalid): sign out.
        await TokenStorage.clear();
        await UserCache.clear();
        state = const AuthState();
      } else {
        await UserCache.save(user);
        state = AuthState(user: user);
      }
    } catch (_) {
      // Offline or the server hiccuped: keep the token and stay signed in
      // with the last known profile instead of kicking the user out.
      final cached = await UserCache.load();
      state = cached != null ? AuthState(user: cached) : const AuthState();
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.login(email, password);
      await UserCache.save(user);
      state = AuthState(user: user);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong.');
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.signup(name, email, password);
      await UserCache.save(user);
      state = AuthState(user: user);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong.');
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    await UserCache.clear();
    state = const AuthState();
  }

  /// Updates name and/or avatar. Throws [AuthException] on failure.
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    String? avatarId,
  }) async {
    final user = await _repo.updateProfile(
      name: name,
      avatarUrl: avatarUrl,
      avatarId: avatarId,
    );
    await UserCache.save(user);
    state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// ─── Cards State ─────────────────────────────────────────────────────────────

class CardsState {
  final List<AddressCard> cards;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const CardsState({
    this.cards = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  CardsState copyWith({
    List<AddressCard>? cards,
    String? nextCursor,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) =>
      CardsState(
        cards: cards ?? this.cards,
        nextCursor: nextCursor ?? this.nextCursor,
        hasMore: hasMore ?? this.hasMore,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
      );
}

class CardsNotifier extends StateNotifier<CardsState> {
  final CardsRepository _repo;
  CardsNotifier(this._repo) : super(const CardsState());

  Future<void> loadCards() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.getCards();
      state = CardsState(
        cards: result.cards,
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
      );
    } on CardsException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load cards.');
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repo.getCards(cursor: state.nextCursor);
      state = state.copyWith(
        cards: [...state.cards, ...result.cards],
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<AddressCard?> createCard({
    required String digipin,
    required String title,
    String humanAddress = '',
    List<String> photoUrls = const [],
    List<String> photoIds = const [],
    String category = '',
    String deliveryNote = '',
    String contactPhone = '',
  }) async {
    try {
      final card = await _repo.createCard(
        digipin: digipin,
        title: title,
        humanAddress: humanAddress,
        photoUrls: photoUrls,
        photoIds: photoIds,
        category: category,
        deliveryNote: deliveryNote,
        contactPhone: contactPhone,
      );
      state = state.copyWith(cards: [card, ...state.cards]);
      return card;
    } on CardsException {
      rethrow; // message is shown to the user by the create screen
    } catch (_) {
      throw const CardsException('Could not save the card. Please try again.');
    }
  }

  void _replace(AddressCard card) {
    state = state.copyWith(
      cards: [for (final c in state.cards) c.id == card.id ? card : c],
    );
  }

  Future<AddressCard?> updateCard(
    String id, {
    String? title,
    String? humanAddress,
    List<String>? photoUrls,
    List<String>? photoIds,
    String? category,
    String? deliveryNote,
    String? contactPhone,
  }) async {
    final card = await _repo.updateCard(
      id,
      title: title,
      humanAddress: humanAddress,
      photoUrls: photoUrls,
      photoIds: photoIds,
      category: category,
      deliveryNote: deliveryNote,
      contactPhone: contactPhone,
    );
    _replace(card);
    return card;
  }

  /// Optimistically flips the favorite flag; rolls back if the request fails.
  Future<bool> toggleFavorite(AddressCard card) async {
    final next = !card.isFavorite;
    _replace(card.copyWith(isFavorite: next));
    try {
      await _repo.updateCard(card.id, isFavorite: next);
      return true;
    } catch (_) {
      _replace(card);
      return false;
    }
  }

  Future<void> deleteCard(String id) async {
    await _repo.deleteCard(id);
    state = state.copyWith(
      cards: state.cards.where((c) => c.id != id).toList(),
    );
  }
}

final cardsProvider = StateNotifierProvider<CardsNotifier, CardsState>((ref) {
  return CardsNotifier(ref.read(cardsRepositoryProvider));
});

// ─── Theme ───────────────────────────────────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _init();
  }

  Future<void> _init() async {
    state = await SettingsStorage.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await SettingsStorage.setThemeMode(mode);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// ─── Sound ───────────────────────────────────────────────────────────────────

class SoundEnabledNotifier extends StateNotifier<bool> {
  SoundEnabledNotifier() : super(true) {
    _init();
  }

  Future<void> _init() async {
    state = await SettingsStorage.getSoundEnabled();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    state = enabled;
    await SettingsStorage.setSoundEnabled(enabled);
  }
}

final soundEnabledProvider =
    StateNotifierProvider<SoundEnabledNotifier, bool>((ref) {
  return SoundEnabledNotifier();
});
