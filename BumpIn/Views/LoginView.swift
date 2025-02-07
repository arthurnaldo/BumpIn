import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @StateObject private var authService = AuthenticationService()
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var showError = false
    @State private var isShowingPasswordRequirements = false
    @State private var isLoading = false
    @StateObject private var userService = UserService()
    @State private var username = ""
    @State private var isCheckingUsername = false
    @State private var usernameAvailable = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.3, blue: 0.5),
                    Color(red: 0.2, green: 0.4, blue: 0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Logo and Title
                    VStack(spacing: 20) {
                        ZStack {
                            // Bottom card
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.2, green: 0.4, blue: 0.8),
                                            Color(red: 0.3, green: 0.5, blue: 0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 60)
                                .rotationEffect(.degrees(10))
                                .offset(x: 20, y: 15)
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            // Middle card
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 90, height: 60)
                                .rotationEffect(.degrees(0))
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            
                            // Top card
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .white,
                                            Color(red: 0.95, green: 0.95, blue: 1.0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 60)
                                .rotationEffect(.degrees(-10))
                                .offset(x: -20, y: -15)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                .overlay(
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.8))
                                        .rotationEffect(.degrees(-10))
                                        .offset(x: -20, y: -15)
                                )
                        }
                        .frame(width: 160, height: 160)
                        
                        // BumpIn Text Treatment
                        HStack(spacing: 0) {
                            Text("Bump")
                                .font(.system(size: 42, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("In")
                                .font(.system(size: 42, weight: .heavy, design: .rounded))
                                .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.9))
                                .padding(.leading, -3)
                        }
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                        
                        Text(isSignUp ? "Create your account" : "Welcome back!")
                            .font(.system(.title3, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 60)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(.subheadline, design: .rounded))
                            
                            TextField("", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: email) { _, _ in
                                    showError = false
                                }
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(.subheadline, design: .rounded))
                            
                            SecureField("", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(isSignUp ? .newPassword : .password)
                                .onChange(of: password) { _, _ in
                                    showError = false
                                    isShowingPasswordRequirements = !password.isEmpty && isSignUp
                                }
                        }
                        
                        if isShowingPasswordRequirements {
                            VStack(alignment: .leading, spacing: 4) {
                                PasswordRequirementView(
                                    text: "At least 8 characters",
                                    isMet: password.count >= 8
                                )
                                PasswordRequirementView(
                                    text: "Contains uppercase letter",
                                    isMet: password.rangeOfCharacter(from: .uppercaseLetters) != nil
                                )
                                PasswordRequirementView(
                                    text: "Contains lowercase letter",
                                    isMet: password.rangeOfCharacter(from: .lowercaseLetters) != nil
                                )
                                PasswordRequirementView(
                                    text: "Contains number",
                                    isMet: password.rangeOfCharacter(from: .decimalDigits) != nil
                                )
                            }
                            .padding(.vertical, 5)
                        }
                        
                        if isSignUp {
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.system(.subheadline, design: .rounded))
                                
                                SecureField("", text: $confirmPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.newPassword)
                                    .onChange(of: confirmPassword) { _, _ in
                                        showError = false
                                    }
                            }
                        }
                        
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.system(.subheadline, design: .rounded))
                                
                                TextField("", text: $username)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .onChange(of: username) { _, newValue in
                                        let sanitized = newValue.lowercased().trimmingCharacters(in: .whitespaces)
                                        if sanitized != newValue {
                                            username = sanitized
                                        }
                                        
                                        Task {
                                            isCheckingUsername = true
                                            do {
                                                try await userService.validateUsername(sanitized)
                                                usernameAvailable = true
                                                showError = false
                                            } catch let error as UserService.ValidationError {
                                                usernameAvailable = false
                                                showError = true
                                                authService.errorMessage = error.localizedDescription
                                            } catch {
                                                usernameAvailable = false
                                                showError = true
                                                authService.errorMessage = "Error checking username"
                                            }
                                            isCheckingUsername = false
                                        }
                                    }
                                
                                if !username.isEmpty {
                                    HStack {
                                        if isCheckingUsername {
                                            ProgressView()
                                                .scaleEffect(0.5)
                                        } else if usernameAvailable {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        } else {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                        
                                        Text(usernameAvailable ? "Username available" : "Username taken")
                                            .font(.caption)
                                            .foregroundColor(usernameAvailable ? .green : .red)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if showError {
                        Text(authService.errorMessage)
                            .foregroundColor(.red)
                            .font(.system(.caption, design: .rounded))
                            .padding(.horizontal)
                            .padding(.top, -10)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button {
                            isLoading = true
                            showError = false
                            Task {
                                if isSignUp && password != confirmPassword {
                                    showError = true
                                    authService.errorMessage = "Passwords do not match"
                                    isLoading = false
                                    return
                                }
                                
                                if isSignUp {
                                    guard usernameAvailable else {
                                        showError = true
                                        authService.errorMessage = "Please choose an available username"
                                        isLoading = false
                                        return
                                    }
                                    
                                    do {
                                        // First create the Firebase Auth user
                                        try await Auth.auth().createUser(withEmail: email, password: password)
                                        // Then create the user document
                                        try await userService.createUser(username: username)
                                        // Verify the user was created successfully
                                        try await userService.fetchCurrentUser()
                                        if userService.currentUser?.username == username {
                                            // Only set authenticated after confirming user creation
                                            isAuthenticated = true
                                        } else {
                                            throw AuthError.userNotFound
                                        }
                                    } catch {
                                        showError = true
                                        authService.errorMessage = error.localizedDescription
                                    }
                                } else {
                                    do {
                                        try await Auth.auth().signIn(withEmail: email, password: password)
                                        isAuthenticated = true
                                    } catch {
                                        showError = true
                                        authService.errorMessage = error.localizedDescription
                                    }
                                }
                                isLoading = false
                            }
                        } label: {
                            ZStack {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.white)
                                    .cornerRadius(12)
                                    .opacity(isLoading ? 0 : 1)
                                
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.5)
                                }
                            }
                        }
                        .disabled(isLoading)
                        .padding(.horizontal, 20)
                        
                        Button {
                            withAnimation {
                                isSignUp.toggle()
                                showError = false
                                authService.errorMessage = ""
                                password = ""
                                confirmPassword = ""
                                isShowingPasswordRequirements = false
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.system(.body, design: .rounded))
                                
                                Text(isSignUp ? "Sign In" : "Sign Up")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.2))
                                    )
                            }
                        }
                        .disabled(isLoading)
                    }
                    .padding(.top, 10)
                }
                .padding(.bottom, 40)
            }
        }
        .onReceive(authService.$user) { user in
            // Only set authenticated state if not in signup process
            if !isSignUp {
                isAuthenticated = user != nil
            }
            // For signup, we handle authentication manually after user creation
        }
    }
} 