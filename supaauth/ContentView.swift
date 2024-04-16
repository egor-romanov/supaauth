//
//  ContentView.swift
//  supaauth
//
//  Created by Egor Romanov on 16.04.2024.
//

import SwiftUI
import IdentifiedCollections
import Functions

struct Note: Identifiable, Codable {
    var id: Int
    var message: String
}

struct ContentView: View {
    @State var appUser: AppUser? = nil
    @State var notes: IdentifiedArrayOf<Note> = []
    @State private var showingSignin = false
    @State var newNote = ""
    @State private var isPerformingTask = false
    @State var search = ""
    @State private var isPerformingSearch = false
    
    let auth = AuthManager.shared
    
    var body: some View {
        VStack {
            if self.appUser == nil {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
            } else {
                HStack {
                    TextField(text: $search, label: {
                        Text("Search")
                    })
                    
                    Button(action: {
                        Task {
                            do {
                                isPerformingSearch = true
                                if search.isEmpty {
                                    notes = try await IdentifiedArrayOf(
                                        uniqueElements: auth.client.database.from("notes")
                                            .select("id,message")
                                            .order("created_at", ascending: false)
                                            .execute()
                                            .value as [Note]
                                    )
                                } else {
                                    notes = try await IdentifiedArrayOf(
                                        uniqueElements: auth.client.functions.invoke(
                                            "search",
                                            options: FunctionInvokeOptions(
                                                body: ["message": search]
                                            )
                                        ) as [Note]
                                    )
                                }
                            } catch {
                                print("error fetching data", error.localizedDescription)
                            }
                            isPerformingSearch = false
                        }
                    }, label: {
                        ZStack {
                            Text("Search")
                                .opacity(isPerformingSearch ? 0 : 1)

                            if isPerformingSearch {
                                ProgressView()
                            }
                        }
                    })
                    .disabled(isPerformingSearch)
                }
                .padding()
                
                List(notes) { note in
                    Text(note.message)
                }.background(content: {
                    RoundedRectangle(cornerRadius: 25.0)
                })
                .refreshable {
                    if self.appUser == nil {
                        self.appUser = await AuthManager.shared.trySignIn()
                        if self.appUser == nil {
                            showingSignin = true
                            return
                        }
                    }
                    if appUser != nil {
                        do {
                            notes = try await IdentifiedArrayOf(
                                uniqueElements: auth.client.database.from("notes")
                                    .select("id,message")
                                    .order("created_at", ascending: false)
                                    .execute()
                                    .value as [Note]
                            )
                            search = ""
                        } catch {
                            print("error fetching data", error.localizedDescription)
                        }
                    }
                }
                
                Spacer()
                
                Group {
                    TextEditor(text: $newNote)
                        .frame(height: 192)
                        .clipShape(RoundedRectangle(cornerRadius: /*@START_MENU_TOKEN@*/25.0/*@END_MENU_TOKEN@*/))
                        .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                        .padding()
                        .contentMargins(10)
                    Button(action: {
                        Task {
                            do {
                                isPerformingTask = true
                                let note = try await auth.client.functions.invoke(
                                    "add-note",
                                    options: FunctionInvokeOptions(
                                        body: ["message": newNote]
                                    )
                                ) as Note
                                notes.insert(note, at: 0)
                                newNote = ""
                            } catch {
                                print("error adding note", error.localizedDescription)
                            }
                            isPerformingTask = false
                        }
                    }, label: {
                        ZStack {
                            Text("Add note")
                                .opacity(isPerformingTask ? 0 : 1)

                            if isPerformingTask {
                                ProgressView()
                            }
                        }
                    })
                    .disabled(isPerformingTask)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingSignin) {
            SignInView { _ in showingSignin = true }
                .environmentObject(AuthManager.shared)
        }
        .task {
            self.appUser = await AuthManager.shared.trySignIn()
            if self.appUser == nil {
                showingSignin = true
                return
            }
            if appUser != nil {
                do {
                    notes = try await IdentifiedArrayOf(
                        uniqueElements: auth.client.database.from("notes")
                            .select("id,message")
                            .order("created_at", ascending: false)
                            .execute()
                            .value as [Note]
                    )
                } catch {
                    print("error fetching data", error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
