import SwiftUI

struct ContentView: View {
    // State variables
    @State private var newItem = ""
    @State private var newNote = "" // Temporary state for adding/editing notes
    @State private var selectedDate = Date()
    @State private var todoItems: [TodoItem] = []
    @State private var completedItems: [TodoItem] = [] // Track completed tasks
    @State private var showDatePicker = false
    @State private var darkMode = false
    @State private var editingNoteID: UUID? = nil // Track the task being edited for its note
    @State private var showCompletedTasks = false // Toggle to show completed tasks
    
    // Generate upcoming dates (next 7 days)
    let upcomingDates: [Date] = {
        let calendar = Calendar.current
        var dates: [Date] = []
        let today = Date()
        dates.append(today)
        for day in 1...6 {
            if let nextDate = calendar.date(byAdding: .day, value: day, to: today) {
                dates.append(nextDate)
            }
        }
        return dates
    }()
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Top Section: Date and Task Input
                VStack {
                    HStack {
                        // Date Picker
                        Text("\(selectedDate, formatter: dateFormatter)")
                            .font(.headline)
                            .foregroundColor(darkMode ? .white : .primary)
                            .frame(width: 120, alignment: .leading)
                            .padding(10)
                            .background(darkMode ? Color.gray.opacity(0.3) : Color.white)
                            .cornerRadius(10)
                            .onTapGesture {
                                withAnimation {
                                    showDatePicker.toggle()
                                }
                            }
                        
                        Spacer()
                        
                        // Task Input Field
                        TextField("New Task", text: $newItem)
                            .padding(12)
                            .background(darkMode ? Color.gray.opacity(0.3) : Color.white)
                            .cornerRadius(10)
                            .foregroundColor(darkMode ? .white : .black)
                            .font(.body)
                        
                        // Add Button (Plus Icon)
                        Button(action: {
                            if !newItem.isEmpty {
                                let newTodo = TodoItem(task: newItem, date: selectedDate, isChecked: false, notes: "")
                                todoItems.append(newTodo)
                                newItem = "" // Clear the task input field
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(darkMode ? .yellow : .blue)
                        }
                        .padding(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, geometry.safeAreaInsets.top)
                    
                    Divider()
                        .frame(height: 1)
                        .background(darkMode ? Color.white : Color.black)
                        .padding(.horizontal)
                }
                
                // Show DatePicker dropdown when clicked on Date
                if showDatePicker {
                    VStack {
                        DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .frame(width: geometry.size.width * 0.8)
                            .padding(.top, 10)
                            .transition(.move(edge: .top)) // Smooth transition for the date picker
                            .animation(.easeInOut, value: showDatePicker)
                        
                        // Dismiss Button for DatePicker
                        Button("Done") {
                            withAnimation {
                                showDatePicker = false
                            }
                        }
                        .padding(.top, 10)
                        .foregroundColor(darkMode ? .yellow : .blue)
                    }
                    .frame(width: geometry.size.width)
                }
                
                // Task List Section
                if !showCompletedTasks {
                    List {
                        ForEach(todoItems) { item in
                            VStack(alignment: .leading) {
                                HStack {
                                    // Date Column
                                    Text("\(item.date, formatter: dateFormatter)")
                                        .foregroundColor(darkMode ? .white : .gray)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    // Task Column
                                    Text(item.task)
                                        .foregroundColor(darkMode ? .white : .primary)
                                        .padding(10)
                                        .background(darkMode ? Color.gray.opacity(0.3) : Color.white)
                                        .cornerRadius(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Checkmark Column
                                    Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                        .onTapGesture {
                                            if let index = todoItems.firstIndex(where: { $0.id == item.id }) {
                                                todoItems[index].isChecked.toggle() // Toggle completion
                                                // Auto-delete the task when completed
                                                if todoItems[index].isChecked {
                                                    completedItems.append(todoItems.remove(at: index)) // Add to completed
                                                }
                                            }
                                        }
                                        .foregroundColor(item.isChecked ? .green : .gray)
                                }
                                
                                // If the note is being edited for this task, show the TextField
                                if editingNoteID == item.id {
                                    TextField("Enter your note...", text: $newNote)
                                        .padding(10)
                                        .background(darkMode ? Color.gray.opacity(0.3) : Color.white)
                                        .cornerRadius(10)
                                        .foregroundColor(darkMode ? .white : .black)
                                        .padding(.top, 5)
                                        .onChange(of: newNote) {
                                            if let index = todoItems.firstIndex(where: { $0.id == item.id }) {
                                                todoItems[index].notes = newNote // Update the note as the user types
                                            }
                                        }
                                } else if !item.notes.isEmpty {
                                    // Display the note if not editing
                                    Text("Notes: \(item.notes)")
                                        .font(.subheadline)
                                        .foregroundColor(darkMode ? .white : .secondary)
                                        .padding(.top, 5)
                                        .padding(.horizontal, 10)
                                }
                                
                                // Toggle editing note mode
                                Button(action: {
                                    if editingNoteID == item.id {
                                        editingNoteID = nil // Dismiss the note field
                                        newNote = "" // Clear the note input field
                                    } else {
                                        editingNoteID = item.id // Start editing the note
                                        newNote = item.notes // Pre-fill the note if it exists
                                    }
                                }) {
                                    Text(editingNoteID == item.id ? "Done" : "Add/Edit Notes")
                                        .foregroundColor(darkMode ? .yellow : .blue)
                                        .padding(.top, 5)
                                        .padding(.leading, 10)
                                }
                            }
                            .padding(.vertical, 5)
                            
                            Divider()
                                .background(darkMode ? Color.white : Color.black)
                                .padding(.horizontal)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(PlainListStyle())
                    .padding(.top, 10)
                } else {
                    // Recently completed tasks section
                    List {
                        ForEach(completedItems) { item in
                            VStack(alignment: .leading) {
                                HStack {
                                    // Date Column
                                    Text("\(item.date, formatter: dateFormatter)")
                                        .foregroundColor(darkMode ? .white : .gray)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    // Task Column
                                    Text(item.task)
                                        .foregroundColor(darkMode ? .white : .primary)
                                        .padding(10)
                                        .background(darkMode ? Color.gray.opacity(0.3) : Color.white)
                                        .cornerRadius(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Checkmark Column
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                
                                // Display the note if available
                                if !item.notes.isEmpty {
                                    Text("Notes: \(item.notes)")
                                        .font(.subheadline)
                                        .foregroundColor(darkMode ? .white : .secondary)
                                        .padding(.top, 5)
                                        .padding(.horizontal, 10)
                                }
                            }
                            .padding(.vertical, 5)
                            
                            Divider()
                                .background(darkMode ? Color.white : Color.black)
                                .padding(.horizontal)
                        }
                    }
                    .listStyle(PlainListStyle())
                    
                    // Button to delete all completed tasks
                    Button(action: {
                        completedItems.removeAll() // Delete all completed tasks
                    }) {
                        Text("Delete All Completed Tasks")
                            .foregroundColor(darkMode ? .yellow : .blue)
                            .padding(.top, 20)
                            .padding(.bottom, 10)
                    }
                    .frame(maxWidth: .infinity)
                    .background(darkMode ? Color.black : Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Bottom Bar with Dark Mode Button and "Show Completed" Button
                Spacer()
                
                HStack {
                    // Recently Completed Button on the left
                    Button(action: {
                        showCompletedTasks.toggle()
                    }) {
                        Text(showCompletedTasks ? "Back to To Do List" : "Show Completed")
                            .foregroundColor(darkMode ? .yellow : .blue)
                            .padding(.bottom, 20)
                    }
                    .padding(.leading, 10)
                    
                    Spacer()
                    
                    // Dark Mode Button
                    Button(action: {
                        darkMode.toggle() // Toggle dark mode
                    }) {
                        Image(systemName: darkMode ? "moon.fill" : "sun.max.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(darkMode ? .yellow : .blue)
                            .padding(10)
                            .background(Circle().stroke(darkMode ? Color.yellow : Color.blue, lineWidth: 2))
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                .background(darkMode ? Color.black : Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            }
            .padding()
            .background(darkMode ? Color.black : Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .edgesIgnoringSafeArea(.bottom) // To ensure no cut-off at the bottom
        }
        .preferredColorScheme(darkMode ? .dark : .light) // Use system dark mode toggle
        .animation(.easeInOut, value: darkMode) // Smooth dark mode transition
    }
    
    // TodoItem model with Identifiable protocol
    struct TodoItem: Identifiable {
        let id = UUID() // Unique identifier for each to-do item
        var task: String
        var date: Date
        var isChecked: Bool
        var notes: String // Notes property for each task
    }
    
    // Delete task function
    func deleteItems(at offsets: IndexSet) {
        todoItems.remove(atOffsets: offsets)
    }
}

// DateFormatter for displaying the date in a readable format
let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short // Show time as well
    return formatter
}()

#Preview {
    ContentView()
}
