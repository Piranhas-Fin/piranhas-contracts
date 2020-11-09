// idea: Dave Fisherman
// developed by TimeusLab
// https://timeus.org

pragma solidity ^0.6.0;

contract PIRPreSale is Ownable {
    using SafeMath for uint256;

    PiranhasToken public pir;
    address payable public PreSaler;
    uint256 public PricePerEther;
    bool public PreSaleStared = false;
    bool public PreSaleClosed = false;
    uint256 public TotalPreSaleTokens;
    uint256 public UnSoldTokens;

    struct Investor{
        address ethAddress;
        uint256 amount;
    }

    Investor[] public WhiteList;


    constructor(
        PiranhasToken _pir,
        uint256 _price,
        uint256 _totalPreSale
    ) public {
        PricePerEther = _price.mul(10**18);
        PreSaler = msg.sender;
        pir = _pir;
        TotalPreSaleTokens = _totalPreSale.mul(10**18);
        UnSoldTokens = _totalPreSale.mul(10**18);
    }

    function addWhiteList(address[] calldata addresses, uint[] calldata amounts) public onlyOwner {
        for(uint i = 0; i<addresses.length; i++){
            WhiteList.push(Investor({
                ethAddress: addresses[i],
                amount:amounts[i]
            }));
        }
        PreSaleStared = true;
    }

    function IsInWhiteList(address buyer) public view returns (bool) {
        bool isInWhiteList = false;
        for(uint i = 0; i< WhiteList.length; i++){
            if(WhiteList[i].ethAddress == buyer){
                isInWhiteList = true;
                i = WhiteList.length;
            }
        }
        return isInWhiteList;
    }

    receive() external payable {
       buy(msg.value);
    }

    function buy(uint256 amount) public payable {
        if(PreSaleClosed && PreSaleStared){
            msg.sender.transfer(amount);
        } else {
            bool isInWhiteList = false;
            Investor memory buyer;
            uint256 index;
            for(uint i = 0; i< WhiteList.length; i++){
                if(WhiteList[i].ethAddress == msg.sender){
                    isInWhiteList = true;
                    index = i;
                    buyer = WhiteList[i];
                    i = WhiteList.length;
                }
            }

            require(isInWhiteList, "You are not in WhiteList");
            require(buyer.amount == amount, "Please provide exactly amount");

            uint256 receivedPir = amount.mul(PricePerEther).div(10**18);
            WhiteList[index].amount = 0;
            UnSoldTokens = UnSoldTokens.sub(receivedPir);
            sendMoney(msg.sender, amount,receivedPir);
        }
    }



    function sendMoney(address _to, uint256 _ethAmount,uint256 pirAmount) internal {
        pir.transfer(_to, pirAmount);
        PreSaler.transfer(_ethAmount);
    }

    function closePreSale() public onlyOwner {
        PreSaleClosed = true;
        uint256 pirBal = pir.balanceOf(address(this));
        pir.transfer(PreSaler, pirBal);
        UnSoldTokens = 0;
    }

    function withdrawEther(uint256 amount) public onlyOwner {
        msg.sender.transfer(amount);
    }


}
