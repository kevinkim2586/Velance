import Foundation
import Alamofire
import SwiftyJSON

class ProductManager {
    
    static let shared = ProductManager()
    
    let interceptor = Interceptor()
    
    //MARK: - End Points
    
    let productAPIBaseUrl           = "\(API.baseUrl)product"
    let productReviewAPIBaseUrl     = "\(API.baseUrl)review"
    
    //MARK: - 제품 목록 가져오기
    func getProducts(
        page: Int,
        productCategoryId: Int,
        onlyMyVegetarianType: String = "N",
        completion: @escaping ((Result<[ProductListResponseDTO], NetworkError>) -> Void)
    ) {
        
        let parameters: Parameters = [
            "request_user_id": User.shared.userUid,
            "page": page,
            "product_category_id": productCategoryId,
            "only_my_vegetarian_type": onlyMyVegetarianType
        ]
        
        AF.request(
            productAPIBaseUrl,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.queryString,
            interceptor: interceptor
        )
            .validate()
            .responseData { response in
                switch response.result {
                case .success(_):
                    print("✏️ ProductManager - getProducts SUCCESS")
                    do {
                        let decodedData = try JSONDecoder().decode([ProductListResponseDTO].self, from: response.data!)
                        completion(.success(decodedData))
                    } catch {
                        print("❗️ ProductManager - getProducts Decoding ERROR: \(error)")
                        completion(.failure(.internalError))
                    }
                case .failure(_):
                    completion(.failure(.internalError))
                }
                
            }
    }
    
    //MARK: - 제품 검색
    func searchProducts(
        page: Int,
        name: String,
        completion: @escaping ((Result<[ProductListResponseDTO], NetworkError>) -> Void)
    ) {
        let parameters: Parameters = [
            "request_user_id": User.shared.userUid,
            "page": page,
            "name": name
        ]
        
        AF.request(
            productAPIBaseUrl,
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.queryString,
            interceptor: interceptor
        )
            .validate()
            .responseData { response in
                switch response.result {
                case .success(_):
                    print("✏️ ProductManager - searchProducts SUCCESS")
                    do {
                        let decodedData = try JSONDecoder().decode([ProductListResponseDTO].self, from: response.data!)
                        completion(.success(decodedData))
                    } catch {
                        print("❗️ ProductManager - searchProducts Decoding ERROR: \(error)")
                        completion(.failure(.internalError))
                    }
                case .failure(_):
                    completion(.failure(.internalError))
                }
            }
    }
    
    //MARK: - 새 제품 등록
    func uploadNewProduct(
        with model: NewProductDTO,
        completion: @escaping ((Result<Bool, NetworkError>) -> Void)
    ) {
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(Data(model.createdBy.utf8),withName: "created_by")
            multipartFormData.append(Data(String(model.productCategoryId).utf8),withName: "product_category_id")
            multipartFormData.append(Data(model.name.utf8),withName: "name")
            multipartFormData.append(Data(String(model.price).utf8),withName: "price")
            multipartFormData.append(
                model.file,
                withName: "files",
                fileName: "\(UUID().uuidString).jpeg",
                mimeType: "image/jpeg"
            )
        },
                  to: productAPIBaseUrl,
                  method: .post,
                  interceptor: interceptor
        )
            .validate()
            .responseData { response in
                
                switch response.result {
                case .success:
                    print("✏️ ProductManager - uploadNewProduct SUCCESS")
                    completion(.success(true))
                case .failure:
                    let error = NetworkError.returnError(statusCode: response.response?.statusCode ?? 400, responseData: response.data ?? Data())
                    completion(.failure(error))
                    print("❗️ ProductManager - uploadNewProduct error: \(error.errorDescription)")
                }
            }
    }
    
    //MARK: - 리뷰 등록
    func uploadNewReview(
        with model: NewReviewDTO,
        completion: @escaping ((Result<Bool, NetworkError>) -> Void)
    ) {
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(Data(model.createdBy.utf8),withName: "created_by")
            multipartFormData.append(Data(String(model.rating).utf8),withName: "rating")
            multipartFormData.append(Data(model.contents.utf8),withName: "contents")
            
            for image in model.files {
                multipartFormData.append(
                    image,
                    withName: "files",
                    fileName: "\(UUID().uuidString).jpeg",
                    mimeType: "image/jpeg"
                )
            }
        },
                  to: productReviewAPIBaseUrl + "/\(model.productId)",
                  method: .post,
                  interceptor: interceptor
        )
            .validate()
            .responseData { response in
                
                switch response.result {
                case .success:
                    print("✏️ ProductManager - uploadNewReview SUCCESS")
                    completion(.success(true))
                case .failure:
                    let error = NetworkError.returnError(statusCode: response.response?.statusCode ?? 400, responseData: response.data ?? Data())
                    completion(.failure(error))
                    print("❗️ ProductManager - uploadNewReview error: \(error.errorDescription)")
                }
            }
    }
    
    //MARK: - 제품 리뷰 가져오기
    func getProductReviews(
        page: Int,
        productId: Int,
        completion: @escaping ((Result<[ProductReviewResponseDTO], NetworkError>) -> Void)
    ) {
        
        let url = productReviewAPIBaseUrl + "/\(productId)?cursor=\(page)"
        
        AF.request(
            url,
            method: .get,
            interceptor: interceptor
        )
            .validate()
            .responseData { response in
                switch response.result {
                case .success(_):
                    print("✏️ ProductManager - getProductReviews SUCCESS")
                    do {
                        let decodedData = try JSONDecoder().decode([ProductReviewResponseDTO].self, from: response.data!)
                        completion(.success(decodedData))
                    } catch {
                        print("❗️ ProductManager - getProductReviews Decoding ERROR: \(error)")
                        completion(.failure(.internalError))
                    }
                    
                case .failure(_):
                    let error = NetworkError.returnError(statusCode: response.response!.statusCode, responseData: response.data ?? Data())
                    print("❗️ ProductManager - getProductReviews failure with error: \(error.errorDescription)")
                    completion(.failure(error))
                }
            }
    }
    
    
    
    
}