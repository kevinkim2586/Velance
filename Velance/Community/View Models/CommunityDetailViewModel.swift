import Foundation

protocol CommunityDetailViewModelDelegate: AnyObject {
    func didFetchDetailInfo()
    func didFetchReplies()
}

class CommunityDetailViewModel {
    
    weak var delegate: CommunityDetailViewModelDelegate?
    
    private var post: FeedDetailResponseDTO?
    private var replies: [ReplyResponseDTO] = []
    var hasMore: Bool = true
    var isFetchingReply: Bool = false
    private var lastReplyID: Int?
    
    func replyAtIndex(_ index: Int) -> CommunityDetailReplyViewModel {
        let reply = replies[index]
        return CommunityDetailReplyViewModel(reply)
    }
}

class CommunityDetailReplyViewModel {
    
    private var reply: ReplyResponseDTO
    
    init(_ reply: ReplyResponseDTO) {
        self.reply = reply
    }
}

extension CommunityDetailViewModel {
    
    func fetchPostInfo(isRecipe: Bool, id: Int) {
        CommunityManager.shared.fetchPostDetail(isRecipe: isRecipe, id: id) { [weak self] result in
            switch result {
            case .success(let data):
                guard let self = self else { return }
                self.post = data
                self.delegate?.didFetchDetailInfo()
            case .failure:
                return
            }
        }
    }
    
    func fetchReplies() {
        guard let feedID = post?.feed?.feedID else {
            print("Empty post...")
            return
        }
        
        CommunityManager.shared.fetchReplies(feedID: feedID) { [weak self] result in
            switch result {
            case .success(let data):
                guard let self = self else { return }
                if data.isEmpty {
                    self.hasMore = false
                } else {
                    self.lastReplyID = data.last?.replyID
                }
                self.replies.append(contentsOf: data)
                self.isFetchingReply = false
                self.delegate?.didFetchReplies()
            case .failure:
                return
            }
        }
    }
    
    var numberOfReplies: Int {
        return replies.count
    }
    
    var conents: String {
        return post?.contents ?? "error"
    }
    
    var feedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.locale = Locale(identifier:"ko_KR")
        guard let createdAt = post?.feed?.createdAt, let date = dateFormatter.date(from: createdAt) else {
            return "시간표시오류"
        }
        dateFormatter.dateFormat = "yyyy.MM.dd"
        return dateFormatter.string(from: date)
    }
    
    var userProfileImageURL: URL? {
        if let files = post?.feed?.user.fileFolder?.files, files.count > 0 {
            return try? files[0].path.asURL()
        }
        return nil
    }
    
    var imageURLs: [URL]? {
        guard let files = post?.fileFolder?.files, files.count > 0 else {
            return nil
        }
        let imageURLs: [URL] = files.map {
            do {
                let url = try $0.path.asURL()
                return url
            } catch {
                print("In CommunityDetailViewModel - error converting string to url: \(error)")
                return nil
            }
        }.compactMap {
            $0
        }
        return imageURLs
    }
    
    var username: String {
        return post?.feed?.user.displayName ?? "error"
    }
    
    var likeCount: Int {
        return post?.feed?.like ?? -1
    }
    
    var repliesCount: Int {
        return post?.feed?.repliesCount ?? -1
    }
}

extension CommunityDetailReplyViewModel {
    
    var replyID: Int {
        return reply.replyID
    }
    
    var contents: String {
        return reply.contents
    }
    
    var replyTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.locale = Locale(identifier:"ko_KR")
        guard let date = dateFormatter.date(from: reply.createdAt) else {
            return "시간표시오류"
        }
        dateFormatter.dateFormat = "yyyy.MM.dd"
        return dateFormatter.string(from: date)
    }
    
    var username: String {
        return reply.user.displayName
    }
    
    var userProfileImageURL: URL? {
        if let files = reply.user.fileFolder?.files, files.count > 0 {
            return try? files[0].path.asURL()
        }
        return nil
    }
}
