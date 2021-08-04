//
//  ContentView.swift
//  Day3_BusApp
//
//  Created by Jeremy Fleshman on 8/4/21.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

struct Bus: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let location: String
    let destination: String
    let passengers: Int
    let fuel: Int
    let image: URL
}

struct BusRow: View {
    let bus: Bus
    let isFavorite: Bool
    
    var body: some View {
        HStack {
            AsyncImage(url: bus.image) { image in
                image.resizable()
            } placeholder: {
                Image(systemName: "bus")
            }
            .frame(width: 64, height: 64)
            .cornerRadius(5)
            
            VStack(alignment: .leading) {
                HStack {
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }

                    Text(bus.name)
                        .font(.headline)
                }
                
                Text("*\(bus.location)* ➠ *\(bus.destination)*")
                    .font(.caption)
                
                HStack(spacing: 5) {
                    Image(systemName: "person.2.circle")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.mint, .indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing)
                        )
                    Text(String(bus.passengers))
                    
                    Spacer()
                        .frame(width: 10)
                    
                    Image(systemName: "fuelpump.circle")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .brown],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing)
                        )
                    Text("\(bus.fuel)%")
                }
            }
        }
        .listRowSeparatorTint(.mint)
    }
}

struct ContentView: View {
    @State private var buses = [Bus]()
    @State private var searchText = ""
    @State private var favorites = Set<Bus>()

    var searchResults: [Bus] {
        if searchText.isEmpty {
            return buses
        } else {
//            return buses.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

            /// Using Reflection -- optimization?
            /// This searches all `String` property fields of `Bus`
            /// Paul isn't a big fan of Mirror since it "figures it out" at runtime
            /// Instead of being at compile time
            /// `Global Variable Oriented Programming` talk by Paul
            return buses.filter { bus in
                let busMirror = Mirror(reflecting: bus)
                var isGood = false

                for child in busMirror.children {
                    if let value = child.value as? String {
                        if value.localizedCaseInsensitiveContains(searchText) {
                            isGood = true
                            break
                        }
                    }
                }

                return isGood
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List(searchResults) { bus in
                BusRow(bus: bus, isFavorite: favorites.contains(bus))
                    .swipeActions {
                        Button {
                            toggle(favorite: bus)
                        } label: {
                            if favorites.contains(bus) {
                                Label("Remove Favorite", systemImage: "star.slash")
                            } else {
                                Label("Add Favorite", systemImage: "star")
                            }
                        }
                    }
            }
            .navigationTitle("Bus Timetable")
            .task {
                if buses.isEmpty {
                    await fetchData()
                }
            }
            .refreshable(action: fetchData)
            .searchable(text: $searchText.animation(), prompt: "Filter results")
        }
    }
    
    func fetchData() async {
        let url = URL(string: "https://www.hackingwithswift.com/samples/bus-timetable")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            buses = try JSONDecoder().decode([Bus].self, from: data)
        } catch {
            print(error.localizedDescription)
        }
    }

    func toggle(favorite bus: Bus) {
        if favorites.contains(bus) {
            favorites.remove(bus)
        } else {
            favorites.insert(bus)
        }
    }
}

struct MyTicketView: View {
    enum Field { case name, reference }

    @EnvironmentObject var userData: UserData
    @FocusState private var focusedField: Field?

    /// Making a QR Code
    /// Using `@State private var` instead of `let` so that SwiftUI doesn't recreate them constantly
    /// Performance optimization
    @State private var context = CIContext()
    @State private var filter = CIFilter.qrCodeGenerator()

    var qrCode: Image {
        let data = Data(userData.identifier.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            if let cgImg = context.createCGImage(outputImage, from: outputImage.extent) {
                let uiImg = UIImage(cgImage: cgImg)
                return Image(uiImage: uiImg)
            }
        }

        return Image(systemName: "xmark.circle")
    }

    var body: some View {
        NavigationView {
            VStack {
                Section {
                    TextField("Customer name", text: $userData.name)
                        .focused($focusedField, equals: .name)
                        .textContentType(.name)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.next)
                        .padding()

                    TextField("Ticket reference number", text: $userData.reference)
                        .focused($focusedField, equals: .reference)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .submitLabel(.done)
                        .padding(.horizontal)

                    qrCode
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 250, height: 250)

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        focusedField = nil
                    }
//                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("My Ticket")
            .onSubmit {
                switch focusedField {
                    case .name:
                        focusedField = .reference
                    default:
                        focusedField = nil
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
