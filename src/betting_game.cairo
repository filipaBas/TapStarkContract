use starknet::ContractAddress;

trait IERC20<TContractState> {
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
}


#[starknet::interface]
trait IBettingContract<TContractState> {
    fn get_prize_pool(self: @TContractState) -> u256;
    fn get_user_points(self: @TContractState, user: ContractAddress) -> u256;
    fn transfer_prize(ref self: TContractState, user: ContractAddress);
    fn place_bet(ref self: TContractState, user: ContractAddress, bet_amount: u256);
    fn claim_winnings(ref self: TContractState, user: ContractAddress);
}

#[starknet::contract]
mod BettingContract {
    
    use super::{ContractAddress, IBettingContract, IERC20};
    use starknet::{get_caller_address, get_contract_address};


    #[storage]
    struct Storage {
        prize_pool: u256,
        user_points: LegacyMap<ContractAddress, u256>,
        user_balances: LegacyMap<ContractAddress, u256>,
        token: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TokenWithdrawn: TokenWithdrawn,
    }
    #[derive(Drop, starknet::Event)]
    struct TokenWithdrawn {
        user: ContractAddress,
        amount: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, token_address: ContractAddress) {
        self.token.write(token_address);
    }

    #[abi(embed_v0)]
    impl BettingContract of super::IBettingContract<ContractState> {
        fn get_prize_pool(self: @ContractState) -> u256 {
            self.prize_pool.read()
        }

        fn get_user_points(self: @ContractState, user: ContractAddress) -> u256 {
            self.user_points.read(user)
        }

        fn place_bet(ref self: ContractState, user: ContractAddress, bet_amount: u256) {
            assert(bet_amount > 0);

            let caller = get_caller_address();
            let contract_address = get_contract_address();

            // Transfer tokens from user to contract
            let token_address = self.token.read();
            let mut token = IERC20Dispatcher { contract_address: token_address };
            token.transfer_from(caller, contract_address, bet_amount);
           

            let current_pool = self.prize_pool.read();
            self.prize_pool.write(current_pool + bet_amount);

            let current_points = self.user_points.read(user);
            self.user_points.write(user, current_points + 50);
        }

        fn transfer_prize(ref self: ContractState, user: ContractAddress) {
            let pool = self.prize_pool.read();
            assert(pool > 0);

            let current_balance = self.user_balances.read(user);
            self.user_balances.write(user, current_balance + pool);
            self.prize_pool.write(0.into());
        }


        fn claim_winnings(ref self: ContractState, user: ContractAddress) {
            let caller = get_caller_address();
            let amount = self.user_balances.read(caller);
            assert(amount == 0 , 'No winnings to claim');

            let token_address = self.token.read();
            let mut token = IERC20Dispatcher { contract_address: token_address };
            token.transfer(caller, amount);
        

            self.user_balances.write(caller, 0.into());

            self.emit(TokenWithdrawn { user: caller, amount });
        }
    }
}