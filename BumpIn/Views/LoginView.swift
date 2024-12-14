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
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("BumpIn")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
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
                                
                                do {
                                    if isSignUp {
                                        try await Auth.auth().createUser(withEmail: email, password: password)
                                    } else {
                                        try await Auth.auth().signIn(withEmail: email, password: password)
                                    }
                                    isAuthenticated = true
                                } catch {
                                    showError = true
                                    authService.errorMessage = error.localizedDescription
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
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.top, 10)
                }
                .padding(.bottom, 40)
            }
        }
        .onReceive(authService.$user) { user in
            isAuthenticated = user != nil
        }
    }
} 