//
//  ContentView.swift
//  AsyncAwait
//
//  Created by macbook on 03/06/2022.
//

import SwiftUI

struct Course: Decodable,Identifiable {
  let id: Int
  let name, link, imageUrl: String
  
}

class ContentViewModel: ObservableObject {
  
  @Published var isFetching = false
  @Published var courses = [Course]()
  
  @Published var errorMessage = ""
  
  init() {
    // fetch data will occur here
    //    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    //      self.isFetching = true
    //    }
  }
  
  @MainActor
  func fetchData() async {
    let urlString = "https://api.letsbuildthatapp.com/jsondecodable/courses"
    guard let url = URL(string: urlString) else { return }
    do {
      isFetching = true
      let (data, response) = try await URLSession.shared.data(from: url)
      if let resp = response as? HTTPURLResponse, resp.statusCode >= 300 {
        self.errorMessage = "Failed Status code"
      }
    
      self.courses = try JSONDecoder().decode([Course].self, from: data)
      isFetching = false
    } catch {
      isFetching = false
      print("Failed to reach endpoint: \(error) ")
    }
  }
}

struct ContentView: View {
  
  @ObservedObject var vm = ContentViewModel()
  
  var body: some View {
    NavigationView {
      ScrollView {
        
        if vm.isFetching {
          ProgressView()
          Text("Is fetching data from internet")
        }
        
        ForEach(vm.courses) { course in
          let url = URL(string: course.imageUrl)
          AsyncImage(url: url) { image in
            image.resizable()
              .scaledToFill()
          } placeholder: {
            ProgressView()
          }
          Text(course.name)
        }
      }
      
      .navigationTitle("Courses")
      
      .task {
        await vm.fetchData()
      }
      
      .navigationBarItems(trailing: refreshButton)
      
    }
  }
  
  private var refreshButton: some View {
    Button {
      Task.init {
        vm.courses.removeAll()
        await vm.fetchData()
      }
    } label: {
      Text("Refresh")
    }
    
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
