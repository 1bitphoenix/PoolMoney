pragma solidity ^0.4.17;
import "./Bid.sol";

contract Group is Bid{
  uint TimeStart; //time stamp of the block 
  mapping(string => address ) address_of_member; //username => wallet address
  mapping(address => member ) member_with_address; //username => wallet address
  uint currtime;
  uint total_members; 
  mapping (address => person) person_with_address;  //maps address to the person structure


  //constructor
  function Group(string _name) public payable {
      TimeStart=now;
      total_members = 1;
      address_of_member[_name]=msg.sender;
      person_with_address[msg.sender]=_name;
  }
  
  //structure of member
  struct member {

    uint addtime;
    uint counter; // number of references
    address member_address;
    string name;
    //for references of the member
    mapping (int => address) refs;
    bool taken_once;
  }

  struct person {
    uint counter; // number of references
    address wallet_address;
    string name;
    //for references of the person
    mapping (int => address) refs;
    
  }
  //trigered when member is added
  event SomeoneTriedToAddSomeone(address personWhoTried,address personWhoWasAdded);
  //trigered when money is deposited
  event SomeoneAddedMoneyToThePool(address personWhoSent,uint moneySent);
  //trigered when requested for loan
  event SomeoneRequestedForMoney(address personWhoRequested,uint requestedM);

  //resets counter for new member
  function onlynew(address newadd){
      if(person_with_address[newadd].refs[1]==0x0)
        person_with_address[newadd].counter=1;
  }

  //check eligibility of member for payments, BY CONSENSUS
  modifier check_eligibility_of_person(address _check_address) {
      require(person_with_address[_check_address].counter >= total_members/2);
        _;
  }

  // //assigns initial members
  // function  members(string _name) {
  //   address_of_member[_name]=msg.sender;
  //   require( total_members <5);
  //     person_with_address[msg.sender]=member(now,4,msg.sender,_name,0x1,0x2,0x3,0x4);
  //     total_members++;
  // }

  function add_Member(address _req_member,string _name) internal  check_eligibility_of_person() {
    person newMem = person_with_address[_req_member];
    member_with_address[_req_member] = member(now,newMem.counter,newMem.wallet_address,newMem.name,newMem.refs,false);
    address_of_member[newMem.name]=_req_member;
  }
  //validates new member by references made along a code
  function add_Member_Request(address _req_member,string _name) onlyMember {

    onlynew(_req_member);
    person_with_address[_req_member].refs[person_with_address[_req_member].counter] = msg.sender;
    person_with_address[_req_member].counter += 1;
    // on enough requests, he will be added as member
    add_Member(_req_member,_name);
    SomeoneTriedToAddSomeone(msg.sender,_req_member);

  }

  //show references of a member
  function list_references(address _master_address) constant returns (string,string,string,string) {

    return (person_with_address[person_with_address[_master_address].refs[1]],person_with_address[person_with_address[_master_address].refs[2]],person_with_address[person_with_address[_master_address].refs[3]],person_with_address[person_with_address[_master_address].refs[4]]);
  }

  //shows the money in the pool
  function getPoolMoney() view returns (uint){

    return this.balance;

  }

  //deposit money in the pool
  function pool(uint _amount) payable {

    this.transfer(_amount);
    SomeoneAddedMoneyToThePool(msg.sender,_amount);

  }

  uint[] public amounts;
//requested money mapped to member address
  mapping (uint => address) amount_map;

  modifier onlyafter6()
  {
      uint memtime=person_with_address[msg.sender].addtime;
      if(memtime==0)
      {
          throw;
      }
      uint nowtime=now;
      uint _days=(nowtime-memtime)/(24*60*60);
      if(_days >= 180)
      {
          _;
      }
      else
      {
          throw;
      }

  }

  //Checks if the member is valid
  modifier onlyMember()
  {
      require(member_with_address[msg.sender].name == person_with_address[msg.sender].name); // the person who sent a request to add that person is a member      
      _;
  }
//To request money from the pool
  function req_Money(uint _amount_) onlyMember {

    amounts.push(_amount_);
    amount_map[_amount_] = msg.sender;

   SomeoneRequestedForMoney(msg.sender,_amount_);
  }

  uint temp;

  function bubble_sort(){

    for(uint j=0;j<amounts.length-1;j++){

      for(uint k=0;k<amounts.length-j-1;k++){

        if(amounts[k]>amounts[k+1]){

          temp = amounts[k];
          amounts[k] = amounts[k+1];
          amounts[k+1] = temp;

        }
      }
    }
  }

  uint sum;

  uint t;

  uint counter_sum=0;
//Total distributable money from the pool
  function assign_loan_amount_from_pool() constant returns (uint){

    sum = 0;

   for(t=0;t<amounts.length;t++){

    if(sum<=amounts[t]){

        sum=sum+amounts[t];
         counter_sum = t;

    }
   }

   return sum;

  }

  function check_time(address ad1) constant returns(uint)
  {
      return(person_with_address[ad1].addtime);
  }
//Address of members who will receive loan
  function displayAllowedForLoan() constant returns(address[]){

    uint length = amounts.length;
    address[] memory addr = new address[](length);

    for(uint q=0; q <= counter_sum; q++ ){

      addr[q] = amount_map[amounts[q]];

    }

    return addr ;
  }

  address temp_address;
//Check if the month is end of three months cycle
  modifier every_3_months {

    uint months=(now-TimeStart)/(24*60*60*30);
    if(months%3==0)
    {
        _;
    }
    else
    {
        throw;
    }

  }
//Pay the members the requested loan amount
  function pay_loan() every_3_months {

    for(uint w=0; w <= counter_sum; w++ ){

      temp_address = amount_map[amounts[w]];
      temp_address.transfer(amounts[w]);

    }
  }

 function getcurrtime() constant returns(uint)
  {

      currtime=now;
      return currtime;
  }

  function () payable{
  }

}
