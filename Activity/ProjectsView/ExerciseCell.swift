//
//  ExerciseCell.swift
//  Activity
//
//  Created by Vivian Wang on 2024/1/24.
//

import SwiftUI

struct ExerciseCell: View {
    var exercise: Project
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(UIColor.secondarySystemGroupedBackground))
            .overlay(
                Text(exercise.name)
                    .foregroundColor(.primary)
            )
    }
}
