import logging
from langchain.llms import Ollama
from langchain.agents import AgentExecutor, create_react_agent
from langchain.prompts import PromptTemplate
from langchain.tools import Tool

logger = logging.getLogger(__name__)

class AgentRunner:
    def __init__(self):
        """Initialize the LangChain agent with Ollama."""
        self.llm = Ollama(model="tinyllama:1.1b-chat-v0.6-q2_K")
        self.tools = self._create_tools()
        self.agent = self._create_agent()
        
    def _create_tools(self):
        """Create the tools available to the agent."""
        # Example tools - these are placeholders
        tools = [
            Tool(
                name="search",
                func=lambda x: "Search results would go here",
                description="Search for information"
            ),
            Tool(
                name="calculator",
                func=lambda x: "Calculation results would go here",
                description="Perform calculations"
            )
        ]
        return tools
        
    def _create_agent(self):
        """Create the LangChain agent."""
        prompt = PromptTemplate.from_template(
            """Answer the following questions as best you can. You have access to the following tools:

            {tools}

            Use the following format:

            Question: the input question you must answer
            Thought: you should always think about what to do
            Action: the action to take, should be one of [{tool_names}]
            Action Input: the input to the action
            Observation: the result of the action
            ... (this Thought/Action/Action Input/Observation can repeat N times)
            Thought: I now know the final answer
            Final Answer: the final answer to the original input question

            Begin!

            Question: {input}
            {agent_scratchpad}"""
        )
        
        agent = create_react_agent(
            llm=self.llm,
            tools=self.tools,
            prompt=prompt
        )
        
        return AgentExecutor.from_agent_and_tools(
            agent=agent,
            tools=self.tools,
            verbose=True
        )
        
    async def get_response(self, text):
        """Get a response from the agent for the given text.
        
        Args:
            text (str): Input text to process
            
        Returns:
            str: Agent's response
        """
        try:
            response = await self.agent.arun(text)
            return response
        except Exception as e:
            logger.error(f"Error getting agent response: {str(e)}")
            return "I'm sorry, I encountered an error processing your request." 