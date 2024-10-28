//
//  TagChoice.swift
//  Activity
//
//  Created by Vivian Wang on 2024/1/24.
//

import SwiftUI
import SwiftData

struct TagChoice: View {
    var onTagsSelected: ([String]) -> ()
    
    @Environment(\.modelContext) var modelContext
    @Query var settingsList: [Settings]
    var settings: Settings? { settingsList.first }
    
    @State var selectedTags: [String] = []
    @State var newTagName: String = ""
    
    init(initial selectedTags: [String] = [], onTagsSelected: @escaping ([String]) -> ()) {
        self.onTagsSelected = onTagsSelected
        self.selectedTags = selectedTags
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    ForEach(settings?.availableTags ?? []) { tag in
                        HStack {
                            if selectedTags.contains(tag.name) {
                                Image(systemName: "checkmark.square.fill")
                                    .foregroundStyle(Color.accentColor)
                            } else {
                                Image(systemName: "squareshape")
                                    .foregroundStyle(.gray)
                            }
                            
                            Text(tag.name)
                        }.onTapGesture {
                            if selectedTags.contains(tag.name) {
                                selectedTags.removeAll(where: { item in item == tag.name })
                            } else {
                                selectedTags.append(tag.name)
                            }
                        }
                    }
                }
                Spacer()
                HStack {
                    TextField("New tag".localized, text: $newTagName)
                    Button(action: {
                        if let settings = settings {
                            settings.availableTags.append(Tag(name: newTagName))
                        } else {
                            let settings = Settings()
                            settings.availableTags.append(Tag(name: newTagName))
                            modelContext.insert(settings)
                        }
                        newTagName = ""
                    }) {
                        Image(systemName: "plus")
                    }.disabled(newTagName.isEmpty)
                }.padding()
            }
            .navigationTitle("Choose Tags".localized)
            .navigationBarItems(
                leading: Button("Cancel".localized) {
                    onTagsSelected([])
                },
                trailing: Button("Save".localized) {
                    onTagsSelected(selectedTags)
                }.disabled(selectedTags.isEmpty)
            )
        }
        
    }
}
