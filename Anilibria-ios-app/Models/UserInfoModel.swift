//
//  UserInfoModel.swift
//  Anilibria-ios-app
//
//  Created by Mansur Nasybullin on 14.10.2023.
//

import UIKit

final class UserInfoModel {
    typealias ResultBlock = Result<(UIImage, String), Error>
    
    func getUserInfo(completionHandler: @escaping (ResultBlock) -> Void) {
        Task {
            do {
                let user = try await requestProfileInfo()
                let userImage = try await requestImage(forURL: user.avatar)
                completionHandler(.success((userImage, user.login)))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
    
    private func requestProfileInfo() async throws -> PUser {
        do {
            let userInfo = try await AuthorizationService.shared.profileInfo()
            guard let data = userInfo.data else {
                let error = MyNetworkError.userIsNotAuthorized
                throw error
            }
            return data
        } catch {
            throw error
        }
    }
    
    private func requestImage(forURL url: String) async throws -> UIImage {
        do {
            let imageData = try await ImageLoaderService.shared.getImageData(from: url)
            guard let image = UIImage(data: imageData) else {
                throw MyImageError.failedToInitialize
            }
            return image
        } catch {
            throw error
        }
    }
}
