import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user.dart';
import '../data/models/address_card.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/cards_repository.dart';
import '../data/local/token_storage.dart';

// ─── Repositories ─────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
final cardsRepositoryProvider = Provider<CardsRepository>((ref) => CardsRepository());

// ─── Auth State ────────────────────────────────────────────────────────────────

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({AppUser? user, bool? isLoading, String? error, bool clearUser = false}) =>
      AuthState(
        user:      clearUser ? null : user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error:     error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final hasToken = await TokenStorage.hasToken();
    if (hasToken) {
      try {
        final user = await _repo.getMe();
        state = AuthState(user: user);
      } catch (_) {
        await TokenStorage.clear();
        state = const AuthState();
      }
    } else {
      state = const AuthState();
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.login(email, password);
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
    state = const AuthState();
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
        cards:          cards ?? this.cards,
        nextCursor:     nextCursor ?? this.nextCursor,
        hasMore:        hasMore ?? this.hasMore,
        isLoading:      isLoading ?? this.isLoading,
        isLoadingMore:  isLoadingMore ?? this.isLoadingMore,
        error:          error,
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
        cards:      result.cards,
        nextCursor: result.nextCursor,
        hasMore:    result.hasMore,
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
        cards:         [...state.cards, ...result.cards],
        nextCursor:    result.nextCursor,
        hasMore:       result.hasMore,
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
    List<String> photoIds  = const [],
  }) async {
    try {
      final card = await _repo.createCard(
        digipin:      digipin,
        title:        title,
        humanAddress: humanAddress,
        photoUrls:    photoUrls,
        photoIds:     photoIds,
      );
      state = state.copyWith(cards: [card, ...state.cards]);
      return card;
    } catch (e) {
      return null;
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

final themeModeProvider = StateProvider<bool>((ref) => true); // true = dark
