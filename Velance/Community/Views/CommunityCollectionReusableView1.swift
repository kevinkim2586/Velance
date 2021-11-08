import UIKit

protocol CommunityCollectionHeaderViewDelegate: AnyObject {
    func didSelectCategoryItemAt(_ index: Int)
    func setViewOnlyFollowing(isSelected: Bool)
    func didSelectChooseInterestButton()
    func didSelectChooseRegionButton()
}

extension CommunityCollectionHeaderViewDelegate {
    func didSelectCategoryItemAt(_ index: Int) {}
    func didSelectChooseInterestButton() {}
    func didSelectChooseRegionButton() {}
}

class CommunityCollectionReusableView1: UICollectionReusableView {
    
    @IBOutlet weak var viewFollowingButton: UIButton!
    @IBOutlet weak var categoryCollectionView: UICollectionView!
    @IBOutlet weak var chooseInterestsButton: VLGradientButton!
  
    @IBOutlet weak var chooseRegionButton: VLGradientButton!
    @IBOutlet weak var recommandLabel: UILabel!
    @IBOutlet weak var similarUserCollectionView: UICollectionView!
    @IBOutlet weak var categoryCollectionViewHeight: NSLayoutConstraint!
    
    private lazy var categoryCellHeight: CGFloat = categoryCollectionViewHeight.constant - 15
    
    private let sectionInsets1 = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    private let sectionInsets2 = UIEdgeInsets(top: 0.0, left: 20.0, bottom: 0.0, right: 20.0)
    private let categories = ["최신순", "한식", "중식", "일식", "분식", "아시아/양식", "카페/디저트"]
    private let categoryReuseIdentifier = "CategoryCollectionViewCell"
    private let similarUserReuseIdentifier = "SimilarUserCollectionViewCell"
    
    private var selectedIndex: Int = 0
    
    weak var delegate: CommunityCollectionHeaderViewDelegate?
    
    private let viewModel = CommunityHeaderViewModel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupCollectionView()
        
        viewModel.delegate = self
        viewModel.fetchRecommendedUser(byTaste: delegate is CommunityRecipeViewController)
    }
    
    private func setupUI() {
        viewFollowingButton.setImage(UIImage(systemName: "square"), for: .normal)
        viewFollowingButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        
        chooseInterestsButton.setTitle("관심사 선택하기", for: .normal)
        chooseInterestsButton.setTitle("관심사 선택됨", for: .selected)
        chooseInterestsButton.addTarget(
            self,
            action: #selector(pressedChooseInterestButton),
            for: .touchUpInside
        )
        
        chooseRegionButton.setTitle("지역 선택하기", for: .normal)
        chooseRegionButton.setTitle("지역 선택됨", for: .selected)
        chooseRegionButton.addTarget(
            self,
            action: #selector(pressedChooseRegionButton),
            for: .touchUpInside
        )
    }
    
    private func setupCollectionView() {
        [categoryCollectionView, similarUserCollectionView].compactMap { $0 }.forEach {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            
            $0.delegate = self
            $0.dataSource = self
            $0.collectionViewLayout = layout
            $0.backgroundColor = .clear
            $0.showsVerticalScrollIndicator = false
            $0.showsHorizontalScrollIndicator = false
        }
        
        similarUserCollectionView.register(UINib(nibName: "SimilarUserCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: similarUserReuseIdentifier)
        let indexPathForFirst = IndexPath(item: 0, section: 0)
        categoryCollectionView.selectItem(at: indexPathForFirst, animated: false, scrollPosition: .left)
    }
    
    @IBAction func viewFollowingButtonTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        delegate?.setViewOnlyFollowing(isSelected: sender.isSelected)
    }
    
    @objc private func pressedChooseInterestButton() {
        delegate?.didSelectChooseInterestButton()
    }
    
    @objc private func pressedChooseRegionButton() {
        delegate?.didSelectChooseRegionButton()
    }
}

extension CommunityCollectionReusableView1: CommunityHeaderViewModelDelegate {
    
    func didFetchUsers() {
        similarUserCollectionView.reloadData()
    }
}

extension CommunityCollectionReusableView1: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoryCollectionView {
            return categories.count
        } else {
            return viewModel.numberOfUsers
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoryCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: categoryReuseIdentifier, for: indexPath) as? CategoryCollectionViewCell else { fatalError() }
            
            cell.categoryLabel.text = categories[indexPath.item]
            cell.layer.cornerRadius = categoryCellHeight/2
            
            if indexPath.item == selectedIndex {
                cell.backgroundColor = UIColor(named: Colors.foodCategorySelectedColor)!
                cell.categoryLabel.textColor = UIColor(named: Colors.appBackgroundColor)!
            } else {
                cell.backgroundColor = .clear
                cell.categoryLabel.textColor = .gray
            }
            
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: similarUserReuseIdentifier, for: indexPath) as? SimilarUserCollectionViewCell else { fatalError() }
            
            let cellViewModel = viewModel.userAtIndex(indexPath.item)
            
            cell.userImageView.sd_setImage(with: cellViewModel.userProfileImageURL,
                                           placeholderImage: UIImage(named: "avatarImage"))
            cell.usernameLabel.text = cellViewModel.username
            cell.userStyleLabel.text = cellViewModel.userType
            
            return cell // 팔로잉 버튼 아직..
        }
    }
}

extension CommunityCollectionReusableView1: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoryCollectionView {
            guard let cell = collectionView.cellForItem(at: indexPath) as? CategoryCollectionViewCell else { return }
            cell.backgroundColor = UIColor(named: Colors.foodCategorySelectedColor)!
            cell.categoryLabel.textColor = UIColor(named: Colors.appBackgroundColor)!
            selectedIndex = indexPath.item
            delegate?.didSelectCategoryItemAt(indexPath.item)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView == categoryCollectionView {
            guard let cell = collectionView.cellForItem(at: indexPath) as? CategoryCollectionViewCell else { return }
            cell.backgroundColor = .clear
            cell.categoryLabel.textColor = .gray
        }
    }
}

extension CommunityCollectionReusableView1: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == categoryCollectionView {
            return CGSize(width: 85, height: categoryCellHeight)
        } else {
            return CGSize(width: 135, height: 185)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == categoryCollectionView {
            return sectionInsets1
        } else {
            return sectionInsets2
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == categoryCollectionView {
            return sectionInsets1.left
        } else {
            return 10
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == categoryCollectionView {
            return sectionInsets1.left
        } else {
            return 10
        }
    }
}
